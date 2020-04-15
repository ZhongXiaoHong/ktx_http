import 'package:dio/dio.dart';

abstract   class  Parser{

  parse<T>(Response response);

}