abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Shell Tabs
  static const String dashboard = '/dashboard';
  static const String accounts = '/accounts';
  static const String pix = '/pix';
  static const String statement = '/statement';
  static const String profile = '/profile';

  // Specific Sub-routes
  static const String newTransaction = '/transactions/new';
  static const String transactionStatus = '/transactions/status';
  static const String transactionDetail = '/transactions/detail';

  static const String pixSend = '/pix/send';
  static const String pixQr = '/pix/qr';
  static const String pixKeys = '/pix/keys';
  static const String pixRegisterKey = '/pix/keys/register';

  static const String createAccount = '/accounts/create';
  static const String accountDetail = '/accounts/detail';
  static const String interestSimulation = '/accounts/interest-simulation';

  static const String reconciliation = '/operations/reconciliation';
  static const String settings = '/settings';
}
