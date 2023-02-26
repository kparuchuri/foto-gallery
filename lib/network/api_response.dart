class ApiResponse<T> {
  Status status;
  T? data;
  String? message;
  String? statusCode;

  ApiResponse.loading() : status = Status.loading;

  ApiResponse.completed(this.data, [this.statusCode]) : status = Status.completed;

  ApiResponse.error(this.message) : status = Status.error;

  @override
  String toString() {
    return "Status : $status \n Message : $message \n Data : $data";
  }
}

enum Status { loading, completed, error }
