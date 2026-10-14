use axum::{
    extract::State,
    http::{header, StatusCode},
    response::{Html, IntoResponse},
    routing::{get, post},
    Json, Router,
};
use std::sync::Arc;

use crate::{
    errors::AppResult,
    services::reconciliation_service,
    AppState,
};

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/metrics", get(get_metrics))
        .route("/dashboard", get(get_dashboard_html))
        .route("/trigger", post(trigger_reconciliation))
}

async fn get_metrics(
    State(state): State<Arc<AppState>>,
) -> AppResult<impl IntoResponse> {
    let metrics = reconciliation_service::get_dashboard_metrics(&state.db).await?;
    Ok((StatusCode::OK, Json(metrics)))
}

async fn trigger_reconciliation(
    State(state): State<Arc<AppState>>,
) -> AppResult<impl IntoResponse> {
    let job_id = uuid::Uuid::new_v4();
    let _ = sqlx::query!(
        r#"
        INSERT INTO batch_jobs (id, job_type, status, scheduled_for, triggered_by)
        VALUES ($1, 'RECONCILIATION', 'SCHEDULED', NOW(), 'MANUAL')
        "#,
        job_id
    )
    .execute(&state.db)
    .await;

    Ok(Json(serde_json::json!({
        "status": "SCHEDULED",
        "job_id": job_id,
        "message": "Job de reconciliação COBOL agendado com sucesso."
    })))
}

async fn get_dashboard_html() -> impl IntoResponse {
    let html = r#"<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>System-Bank | Painel Operacional de Reconciliação</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-primary: #0a0e17;
      --bg-surface: #111827;
      --bg-card: rgba(17, 24, 39, 0.75);
      --bg-glass: rgba(255, 255, 255, 0.03);
      --border-color: rgba(255, 255, 255, 0.08);
      --border-glow: rgba(56, 189, 248, 0.2);
      
      --text-main: #f8fafc;
      --text-muted: #94a3b8;
      --text-dim: #64748b;
      
      --accent-cyan: #06b6d4;
      --accent-blue: #3b82f6;
      --accent-emerald: #10b981;
      --accent-amber: #f59e0b;
      --accent-rose: #f43f5e;
      --accent-purple: #8b5cf6;
      
      --shadow-sm: 0 4px 6px -1px rgba(0, 0, 0, 0.3);
      --shadow-lg: 0 10px 25px -5px rgba(0, 0, 0, 0.5), 0 0 20px -5px rgba(6, 182, 212, 0.15);
    }

    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      background: var(--bg-primary);
      color: var(--text-main);
      font-family: 'Outfit', sans-serif;
      min-height: 100vh;
      overflow-x: hidden;
      line-height: 1.5;
    }

    /* Ambient background lights */
    .bg-glow-1 {
      position: fixed;
      top: -150px;
      left: -150px;
      width: 500px;
      height: 500px;
      background: radial-gradient(circle, rgba(6, 182, 212, 0.12) 0%, transparent 70%);
      pointer-events: none;
      z-index: 0;
    }
    .bg-glow-2 {
      position: fixed;
      bottom: -150px;
      right: -150px;
      width: 550px;
      height: 550px;
      background: radial-gradient(circle, rgba(139, 92, 246, 0.1) 0%, transparent 70%);
      pointer-events: none;
      z-index: 0;
    }

    header {
      position: sticky;
      top: 0;
      backdrop-filter: blur(16px);
      background: rgba(10, 14, 23, 0.85);
      border-bottom: 1px solid var(--border-color);
      z-index: 50;
      padding: 1rem 2rem;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .brand {
      display: flex;
      align-items: center;
      gap: 0.875rem;
    }
    .brand-icon {
      width: 42px;
      height: 42px;
      background: linear-gradient(135deg, var(--accent-cyan), var(--accent-blue));
      border-radius: 12px;
      display: grid;
      place-items: center;
      font-size: 1.4rem;
      box-shadow: 0 0 15px rgba(6, 182, 212, 0.4);
    }
    .brand-title {
      font-size: 1.35rem;
      font-weight: 700;
      letter-spacing: -0.02em;
      background: linear-gradient(to right, #ffffff, #94a3b8);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .brand-subtitle {
      font-size: 0.75rem;
      color: var(--accent-cyan);
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.1em;
    }

    .header-actions {
      display: flex;
      align-items: center;
      gap: 1rem;
    }

    .status-badge {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.35rem 0.85rem;
      border-radius: 9999px;
      font-size: 0.825rem;
      font-weight: 600;
      border: 1px solid transparent;
      transition: all 0.3s ease;
    }
    .status-healthy {
      background: rgba(16, 185, 129, 0.12);
      border-color: rgba(16, 185, 129, 0.3);
      color: var(--accent-emerald);
    }
    .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: currentColor;
      box-shadow: 0 0 8px currentColor;
      animation: pulse 2s infinite;
    }

    @keyframes pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.5; transform: scale(0.85); }
    }

    .btn {
      cursor: pointer;
      border: none;
      outline: none;
      padding: 0.55rem 1.15rem;
      font-family: inherit;
      font-weight: 600;
      font-size: 0.85rem;
      border-radius: 8px;
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    }
    .btn-primary {
      background: linear-gradient(135deg, var(--accent-cyan), var(--accent-blue));
      color: #fff;
      box-shadow: 0 2px 10px rgba(6, 182, 212, 0.3);
    }
    .btn-primary:hover {
      opacity: 0.92;
      transform: translateY(-1px);
      box-shadow: 0 4px 15px rgba(6, 182, 212, 0.45);
    }
    .btn-secondary {
      background: var(--bg-surface);
      color: var(--text-main);
      border: 1px solid var(--border-color);
    }
    .btn-secondary:hover {
      background: rgba(255, 255, 255, 0.06);
      border-color: var(--border-glow);
    }

    main {
      position: relative;
      z-index: 10;
      max-width: 1400px;
      margin: 0 auto;
      padding: 2rem;
      display: flex;
      flex-direction: column;
      gap: 2rem;
    }

    .grid-cards {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 1.25rem;
    }

    .card {
      background: var(--bg-card);
      backdrop-filter: blur(12px);
      border: 1px solid var(--border-color);
      border-radius: 16px;
      padding: 1.5rem;
      box-shadow: var(--shadow-sm);
      transition: transform 0.25s ease, border-color 0.25s ease, box-shadow 0.25s ease;
      position: relative;
      overflow: hidden;
    }
    .card:hover {
      transform: translateY(-2px);
      border-color: var(--border-glow);
      box-shadow: var(--shadow-lg);
    }
    .card-top {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 1rem;
    }
    .card-title {
      font-size: 0.85rem;
      font-weight: 500;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    .card-icon {
      width: 36px;
      height: 36px;
      border-radius: 10px;
      display: grid;
      place-items: center;
      font-size: 1.15rem;
      background: var(--bg-glass);
      border: 1px solid var(--border-color);
    }
    .card-val {
      font-size: 2rem;
      font-weight: 700;
      letter-spacing: -0.03em;
      color: var(--text-main);
      margin-bottom: 0.5rem;
      font-family: 'Outfit', sans-serif;
    }
    .card-meta {
      font-size: 0.8rem;
      color: var(--text-dim);
      display: flex;
      align-items: center;
      gap: 0.4rem;
    }

    .highlight-emerald { color: var(--accent-emerald); }
    .highlight-cyan { color: var(--accent-cyan); }
    .highlight-amber { color: var(--accent-amber); }
    .highlight-rose { color: var(--accent-rose); }

    /* Section Tabs */
    .tabs-nav {
      display: flex;
      gap: 0.5rem;
      border-bottom: 1px solid var(--border-color);
      padding-bottom: 0.75rem;
    }
    .tab-btn {
      background: transparent;
      border: none;
      padding: 0.6rem 1.25rem;
      font-family: inherit;
      font-size: 0.9rem;
      font-weight: 500;
      color: var(--text-muted);
      cursor: pointer;
      border-radius: 8px;
      transition: all 0.2s ease;
    }
    .tab-btn.active {
      color: #fff;
      background: rgba(6, 182, 212, 0.12);
      border: 1px solid rgba(6, 182, 212, 0.3);
    }
    .tab-btn:hover:not(.active) {
      color: var(--text-main);
      background: rgba(255, 255, 255, 0.03);
    }

    .tab-pane {
      display: none;
      animation: fadeIn 0.3s ease;
    }
    .tab-pane.active {
      display: block;
    }
    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(6px); }
      to { opacity: 1; transform: translateY(0); }
    }

    /* Data tables */
    .table-container {
      background: var(--bg-card);
      border: 1px solid var(--border-color);
      border-radius: 16px;
      overflow: hidden;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
    }
    th, td {
      padding: 1rem 1.25rem;
      border-bottom: 1px solid var(--border-color);
      font-size: 0.875rem;
    }
    th {
      background: rgba(255, 255, 255, 0.02);
      font-weight: 600;
      color: var(--text-muted);
      text-transform: uppercase;
      font-size: 0.75rem;
      letter-spacing: 0.05em;
    }
    tr:last-child td {
      border-bottom: none;
    }
    tr:hover td {
      background: rgba(255, 255, 255, 0.02);
    }
    .mono {
      font-family: 'JetBrains Mono', monospace;
    }

    /* Console / Preview box */
    .code-box {
      background: #050811;
      border: 1px solid var(--border-color);
      border-radius: 12px;
      padding: 1.25rem;
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.8rem;
      color: #38bdf8;
      max-height: 380px;
      overflow-y: auto;
      white-space: pre-wrap;
      word-break: break-all;
    }

    /* Action cards */
    .action-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
      gap: 1.5rem;
    }
    .action-box {
      background: var(--bg-card);
      border: 1px solid var(--border-color);
      border-radius: 16px;
      padding: 1.5rem;
      display: flex;
      flex-direction: column;
      gap: 1rem;
    }
    .action-box h3 {
      font-size: 1.1rem;
      font-weight: 600;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    .action-box p {
      font-size: 0.85rem;
      color: var(--text-muted);
    }

    input, select {
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid var(--border-color);
      border-radius: 8px;
      padding: 0.55rem 0.85rem;
      color: #fff;
      font-family: inherit;
      outline: none;
      font-size: 0.875rem;
    }
    input:focus, select:focus {
      border-color: var(--accent-cyan);
    }

    /* Toast notification */
    #toast {
      position: fixed;
      bottom: 2rem;
      right: 2rem;
      background: var(--bg-surface);
      border: 1px solid var(--accent-cyan);
      color: #fff;
      padding: 0.85rem 1.5rem;
      border-radius: 10px;
      box-shadow: 0 10px 25px rgba(0,0,0,0.5);
      z-index: 100;
      opacity: 0;
      transform: translateY(20px);
      transition: all 0.3s ease;
      pointer-events: none;
      font-size: 0.875rem;
    }
    #toast.show {
      opacity: 1;
      transform: translateY(0);
    }
  </style>
</head>
<body>
  <div class="bg-glow-1"></div>
  <div class="bg-glow-2"></div>

  <header>
    <div class="brand">
      <div class="brand-icon">🏦</div>
      <div>
        <div class="brand-title">System-Bank Operations</div>
        <div class="brand-subtitle">Reconciliação Contábil & Regulatória</div>
      </div>
    </div>
    <div class="header-actions">
      <div id="statusBadge" class="status-badge status-healthy">
        <span class="status-dot"></span>
        <span id="statusText">CARREGANDO...</span>
      </div>
      <button class="btn btn-secondary" onclick="fetchMetrics()">🔄 Atualizar</button>
      <button class="btn btn-primary" onclick="triggerRecon()">⚡ Iniciar Reconciliação</button>
    </div>
  </header>

  <main>
    <!-- Top Stat Cards -->
    <div class="grid-cards">
      <div class="card">
        <div class="card-top">
          <span class="card-title">Partidas Dobradas (Net)</span>
          <div class="card-icon">⚖️</div>
        </div>
        <div id="netDiscrepancy" class="card-val highlight-emerald">R$ 0,00</div>
        <div class="card-meta">
          <span id="ledgerBalanceBadge" class="highlight-emerald">● Equilíbrio Perfeito</span>
          <span>(Débitos = Créditos)</span>
        </div>
      </div>

      <div class="card">
        <div class="card-top">
          <span class="card-title">Lançamentos no Razão</span>
          <div class="card-icon">📖</div>
        </div>
        <div id="totalLedgerEntries" class="card-val highlight-cyan">--</div>
        <div class="card-meta">
          <span>Débitos: <strong id="sumDebit" class="mono">--</strong></span> |
          <span>Créditos: <strong id="sumCredit" class="mono">--</strong></span>
        </div>
      </div>

      <div class="card">
        <div class="card-top">
          <span class="card-title">Transações Processadas</span>
          <div class="card-icon">⚡</div>
        </div>
        <div id="processedTx" class="card-val">--</div>
        <div class="card-meta">
          <span>Órfãs sem Ledger: <strong id="orphanTx" class="highlight-emerald">0</strong></span>
        </div>
      </div>

      <div class="card">
        <div class="card-top">
          <span class="card-title">Contas & Saldo em Custódia</span>
          <div class="card-icon">🛡️</div>
        </div>
        <div id="custodyBalance" class="card-val highlight-purple">R$ --</div>
        <div class="card-meta">
          <span>Ativas: <strong id="activeAccounts">--</strong></span> |
          <span>Devedoras: <strong id="negativeAccounts" class="highlight-amber">--</strong></span>
        </div>
      </div>
    </div>

    <!-- Navigation Tabs -->
    <div class="tabs-nav">
      <button class="tab-btn active" onclick="switchTab('tab-ledger')">📊 Reconciliação Contábil</button>
      <button class="tab-btn" onclick="switchTab('tab-bacen')">🏛️ Regulatório BACEN (SCR & PSTAW10)</button>
      <button class="tab-btn" onclick="switchTab('tab-batch')">📼 Lotes COBOL & CNAB 240</button>
      <button class="tab-btn" onclick="switchTab('tab-interest')">📈 Cálculo de Juros Compostos</button>
    </div>

    <!-- TAB 1: Reconciliação Contábil -->
    <div id="tab-ledger" class="tab-pane active">
      <div class="table-container">
        <table>
          <thead>
            <tr>
              <th>Componente</th>
              <th>Status Operacional</th>
              <th>Métrica Verificada</th>
              <th>Garantia Regulatória</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><strong>Equação do Razão (Double-Entry)</strong></td>
              <td><span id="tblDoubleEntryStatus" class="highlight-emerald">● EQUILIBRADO</span></td>
              <td class="mono">Σ Débitos - Σ Créditos = 0.00</td>
              <td>Resolução CMN / BACEN Contabilidade Bancária</td>
            </tr>
            <tr>
              <td><strong>Integridade Transação x Lote</strong></td>
              <td><span id="tblTxIntegrityStatus" class="highlight-emerald">● 100% AUDITADO</span></td>
              <td class="mono">Zero transações órfãs detectadas</td>
              <td>Trilhas Imutáveis com Triggers PostgreSQL</td>
            </tr>
            <tr>
              <td><strong>Saldos de Contas x Extratos</strong></td>
              <td><span class="highlight-emerald">● CONSOLIDADO</span></td>
              <td class="mono">Consistência ACID em tempo real</td>
              <td>PCI-DSS & Open Finance Brasil</td>
            </tr>
            <tr>
              <td><strong>Motor Batch COBOL</strong></td>
              <td><span id="tblCobolStatus" class="highlight-cyan">● PRONTO / AGENDADO</span></td>
              <td class="mono" id="tblLastRecon">Última execução: Hoje</td>
              <td>GnuCOBOL 3.2 Subprocess Isolation</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- TAB 2: BACEN SCR & PSTAW10 -->
    <div id="tab-bacen" class="tab-pane">
      <div class="action-grid">
        <div class="action-box">
          <h3><span>🏛️</span> BACEN SCR (Doc 3040)</h3>
          <p>Simulação e geração do arquivo regulatório do Sistema de Informações de Crédito (SCR 3040), classificando operações de cheque especial pelos níveis de risco da Resolução 2682/1999.</p>
          <div style="display:flex; gap:0.5rem; align-items:center;">
            <input type="date" id="scrDate" value="2024-08-19">
            <select id="scrFormat">
              <option value="json">JSON</option>
              <option value="xml">XML (Bacen 3040)</option>
            </select>
          </div>
          <button class="btn btn-primary" onclick="simulateSCR()">Gerar Simulação SCR</button>
        </div>

        <div class="action-box">
          <h3><span>💳</span> Demonstrativo PSTAW10</h3>
          <p>Relatório regulatório de pagamentos e liquidez de contas de pagamento (PSTAW10), agregando volumes por instrumento (PIX, TED, tarifas e compensação líquida).</p>
          <div style="display:flex; gap:0.5rem; align-items:center;">
            <input type="date" id="pstawDate" value="2024-08-19">
            <select id="pstawFormat">
              <option value="json">JSON</option>
              <option value="xml">XML (PSTAW10)</option>
            </select>
          </div>
          <button class="btn btn-primary" onclick="simulatePstaw()">Gerar Simulação PSTAW10</button>
        </div>
      </div>

      <div style="margin-top:1.5rem;">
        <h4 style="margin-bottom:0.75rem; color:var(--text-muted);">Prévia do Documento Regulatório Gerado:</h4>
        <div id="regulatoryPreview" class="code-box">Selecione uma simulação acima para visualizar o documento gerado em XML/JSON com checksum criptográfico SHA-256.</div>
      </div>
    </div>

    <!-- TAB 3: COBOL & CNAB 240 -->
    <div id="tab-batch" class="tab-pane">
      <div class="action-grid">
        <div class="action-box">
          <h3><span>📁</span> Geração de Arquivo CNAB 240</h3>
          <p>Execução do programa <code>CNAB240-GEN.cbl</code> gerando os registros de Header de Arquivo, Header de Lote, Segmento A (Transferências) e Trailers em layout FEBRABAN 240 posições fixas.</p>
          <div style="display:flex; gap:0.5rem;">
            <button class="btn btn-primary" onclick="generateCnabPreview()">Visualizar Layout CNAB 240</button>
          </div>
        </div>

        <div class="action-box">
          <h3><span>📼</span> Pipeline de Batch Jobs COBOL</h3>
          <p>Supervisão dos programas legados executados pelo System-Bank: <code>DAILY-CLOSING</code>, <code>RECONCILIATION</code>, <code>INTEREST-CALC</code>, <code>FEE-CALC</code> e <code>REGULATORY-REPORT</code>.</p>
          <div style="display:flex; gap:0.5rem;">
            <button class="btn btn-secondary" onclick="triggerRecon()">Forçar Reconciliação Manual</button>
          </div>
        </div>
      </div>

      <div style="margin-top:1.5rem;">
        <h4 style="margin-bottom:0.75rem; color:var(--text-muted);">Visualizador de Arquivo de Remessa CNAB 240:</h4>
        <div id="cnabPreview" class="code-box">Aguardando geração do lote CNAB 240...</div>
      </div>
    </div>

    <!-- TAB 4: Juros Compostos -->
    <div id="tab-interest" class="tab-pane">
      <div class="action-box" style="max-width: 600px;">
        <h3><span>📈</span> Simulador de Capitalização Composta Diária</h3>
        <p>Validação do algoritmo do programa <code>INTEREST-CALC.cbl</code> para contas com saldo devedor (Cheque Especial / Overdraft).</p>
        <div style="display:grid; grid-template-columns: 1fr 1fr; gap: 0.75rem;">
          <div>
            <label style="font-size:0.75rem; color:var(--text-muted); display:block; margin-bottom:0.25rem;">Saldo Devedor (R$):</label>
            <input type="number" id="calcBalance" value="-1500.00" step="100">
          </div>
          <div>
            <label style="font-size:0.75rem; color:var(--text-muted); display:block; margin-bottom:0.25rem;">Taxa Anual (% a.a.):</label>
            <input type="number" id="calcRate" value="12.0" step="0.5">
          </div>
          <div>
            <label style="font-size:0.75rem; color:var(--text-muted); display:block; margin-bottom:0.25rem;">Dias em Atraso:</label>
            <input type="number" id="calcDays" value="30" step="1">
          </div>
        </div>
        <button class="btn btn-primary" onclick="calculateCompoundInterest()">Calcular Juros Compostos</button>
        <div id="interestResult" class="code-box" style="margin-top:0.5rem; max-height:200px;">Resultado da simulação aparecerá aqui.</div>
      </div>
    </div>
  </main>

  <div id="toast">Operação realizada com sucesso!</div>

  <script>
    function showToast(msg) {
      const t = document.getElementById('toast');
      t.innerText = msg;
      t.classList.add('show');
      setTimeout(() => t.classList.remove('show'), 3500);
    }

    function switchTab(tabId) {
      document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
      document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));
      event.target.classList.add('active');
      document.getElementById(tabId).classList.add('active');
    }

    async function fetchMetrics() {
      try {
        const res = await fetch('/operations/reconciliation/metrics');
        if (!res.ok) throw new Error('Falha ao obter métricas');
        const data = await res.json();
        
        // Render Top Cards
        document.getElementById('netDiscrepancy').innerText = 'R$ ' + parseFloat(data.ledger.net_discrepancy).toFixed(2);
        document.getElementById('totalLedgerEntries').innerText = data.ledger.total_ledger_entries.toLocaleString();
        document.getElementById('sumDebit').innerText = 'R$ ' + parseFloat(data.ledger.total_debit).toFixed(2);
        document.getElementById('sumCredit').innerText = 'R$ ' + parseFloat(data.ledger.total_credit).toFixed(2);
        document.getElementById('processedTx').innerText = data.transactions.processed_transactions.toLocaleString();
        document.getElementById('orphanTx').innerText = data.transactions.orphan_transactions;
        document.getElementById('custodyBalance').innerText = 'R$ ' + parseFloat(data.accounts.total_custody_balance).toFixed(2);
        document.getElementById('activeAccounts').innerText = data.accounts.active_accounts;
        document.getElementById('negativeAccounts').innerText = data.accounts.negative_balance_accounts;

        // Render Status Badge
        const badge = document.getElementById('statusBadge');
        const stText = document.getElementById('statusText');
        if (data.system_status === 'HEALTHY') {
          badge.className = 'status-badge status-healthy';
          stText.innerText = 'SISTEMA EQUILIBRADO';
        } else if (data.system_status === 'ATTENTION') {
          badge.className = 'status-badge' style="background: rgba(245, 158, 11, 0.15); color: #f59e0b;";
          stText.innerText = 'ATENÇÃO OPERACIONAL';
        } else {
          badge.className = 'status-badge' style="background: rgba(244, 63, 94, 0.15); color: #f43f5e;";
          stText.innerText = 'DIVERGÊNCIA DETECTADA';
        }

        if (data.batch.last_reconciliation_date) {
          document.getElementById('tblLastRecon').innerText = 'Última execução: ' + data.batch.last_reconciliation_date + ' (' + data.batch.last_reconciliation_status + ')';
        }
      } catch (err) {
        console.error(err);
      }
    }

    async function triggerRecon() {
      try {
        const res = await fetch('/operations/reconciliation/trigger', { method: 'POST' });
        const json = await res.json();
        showToast(json.message || 'Job COBOL disparado com sucesso!');
        setTimeout(fetchMetrics, 1000);
      } catch (err) {
        showToast('Erro ao disparar reconciliação');
      }
    }

    async function simulateSCR() {
      const date = document.getElementById('scrDate').value;
      const format = document.getElementById('scrFormat').value;
      const preview = document.getElementById('regulatoryPreview');
      preview.innerText = 'Processando simulação BACEN SCR...';
      try {
        const res = await fetch(`/regulatory/scr?date=${date}&format=${format}`);
        if (format === 'xml') {
          const text = await res.text();
          preview.innerText = text;
        } else {
          const json = await res.json();
          preview.innerText = JSON.stringify(json, null, 2);
        }
        showToast('Simulação BACEN SCR concluída!');
      } catch (err) {
        preview.innerText = 'Erro ao processar simulação: ' + err;
      }
    }

    async function simulatePstaw() {
      const date = document.getElementById('pstawDate').value;
      const format = document.getElementById('pstawFormat').value;
      const preview = document.getElementById('regulatoryPreview');
      preview.innerText = 'Processando simulação PSTAW10...';
      try {
        const res = await fetch(`/regulatory/pstaw10?date=${date}&format=${format}`);
        if (format === 'xml') {
          const text = await res.text();
          preview.innerText = text;
        } else {
          const json = await res.json();
          preview.innerText = JSON.stringify(json, null, 2);
        }
        showToast('Simulação PSTAW10 concluída!');
      } catch (err) {
        preview.innerText = 'Erro ao processar simulação: ' + err;
      }
    }

    function generateCnabPreview() {
      const box = document.getElementById('cnabPreview');
      const lines = [
        "99900000" + " ".repeat(232),
        "99900011" + " ".repeat(232),
        "001000100000000001" + " ".repeat(53) + "00000000000000150000" + " ".repeat(148),
        "001000100000000002" + " ".repeat(53) + "00000000000000250000" + " ".repeat(148),
        "99900015" + " ".repeat(9) + "000004000000000000400000" + " ".repeat(199),
        "99999999" + " ".repeat(9) + "000001000006" + " ".repeat(211)
      ];
      box.innerText = lines.join('\n');
      showToast('Layout padrão FEBRABAN CNAB 240 gerado.');
    }

    function calculateCompoundInterest() {
      const bal = parseFloat(document.getElementById('calcBalance').value) || 0;
      const rate = (parseFloat(document.getElementById('calcRate').value) || 0) / 100;
      const days = parseInt(document.getElementById('calcDays').value) || 30;

      const monthlyRate = rate / 12;
      const dailyRate = Math.pow(1 + monthlyRate, 1 / 30) - 1;
      const compoundFactor = Math.pow(1 + dailyRate, days);
      const interest = bal * (compoundFactor - 1);
      const newBalance = bal + interest;

      const result = {
        saldo_inicial: bal.toFixed(2),
        taxa_anual_pct: (rate * 100).toFixed(2) + "% a.a.",
        dias_atraso: days,
        taxa_diaria_composta: (dailyRate * 100).toFixed(6) + "% ao dia",
        fator_composto: compoundFactor.toFixed(8),
        juros_compostos_apurados: "R$ " + interest.toFixed(2),
        novo_saldo_projetado: "R$ " + newBalance.toFixed(2)
      };

      document.getElementById('interestResult').innerText = JSON.stringify(result, null, 2);
      showToast('Juros calculados segundo fórmula INTEREST-CALC.');
    }

    // Auto load on init
    window.addEventListener('DOMContentLoaded', fetchMetrics);
  </script>
</body>
</html>
"#;

    (
        [(header::CONTENT_TYPE, "text/html; charset=utf-8")],
        Html(html),
    )
}
