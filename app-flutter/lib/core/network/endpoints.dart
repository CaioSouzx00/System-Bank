class Endpoints {
  // Base Health
  static const String health = '/health';

  // Accounts
  static const String accounts = '/accounts';
  static String accountById(String id) => '/accounts/$id';
  static String accountBlock(String id) => '/accounts/$id/block';
  static String accountStatement(String id) => '/accounts/$id/statement';
  static String accountInterestSimulation(String id) => '/accounts/$id/interest-simulation';

  // Transactions
  static const String transactions = '/transactions';
  static String transactionById(String id) => '/transactions/$id';

  // PIX
  static const String pixKeys = '/pix/keys';
  static String pixKeyById(String id) => '/pix/keys/$id';
  static const String pixPayment = '/pix/payment';
  static String pixQrCode(String key) => '/pix/qrcode/$key';

  // Operations & Reconciliation (OPERATOR & ADMIN only)
  static const String reconciliationMetrics = '/operations/reconciliation/metrics';
  static const String reconciliationTrigger = '/operations/reconciliation/trigger';

  // Regulatory (BACEN SCR & PSTAW10)
  static const String regulatoryScr = '/regulatory/scr';
  static const String regulatoryPstaw10 = '/regulatory/pstaw10';
}
