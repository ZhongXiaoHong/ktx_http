import 'package:dio/dio.dart';


///抽象的转换器：将T类型转换成MultipartFile
abstract class  MultiPartFileConverter<T>{
  Future<MultipartFile> convert(T  t);
}
