import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> sendVerificationEmail({
  required String toEmail,
  required String code,
}) async {
  final host = dotenv.env['SMTP_HOST'];
  final portStr = dotenv.env['SMTP_PORT'];
  final user = dotenv.env['SMTP_USER'];
  final pass = dotenv.env['SMTP_PASS'];

  if (host == null || portStr == null || user == null || pass == null) {
    throw Exception("Credenciales SMTP no configuradas");
  }

  final port = int.tryParse(portStr);
  if (port == null) {
    throw Exception("Puerto SMTP inválido: $portStr");
  }

  final smtpServer = SmtpServer(
    host,
    port: port,
    username: user,
    password: pass,
  );

  final message = Message()
    ..from = Address(user, 'MyDearMap')
    ..recipients.add(toEmail)
    ..subject = 'Código de verificación'
    ..text = 'Tu código de verificación es: $code';

  try {
    final sendReport = await send(message, smtpServer);
    print('Correo enviado: $sendReport');
  } on MailerException catch (e) {
    print('Error enviando correo: $e');
    rethrow;
  }
}
