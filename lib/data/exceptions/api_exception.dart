class APIException implements Exception {
  final String message;
  final int statusCode;
  final String statusText;

  APIException(this.message, this.statusCode, this.statusText);
}

class ErrorMsg {
  String message;
  int errorCode;

  ErrorMsg({
    required this.message,
    required this.errorCode,
  });

  factory ErrorMsg.fromJson(Map<String, dynamic> json) => ErrorMsg(
        message: json['message'],
        errorCode: json['code'],
      );
}
