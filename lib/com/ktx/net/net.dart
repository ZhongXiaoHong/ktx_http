import 'dart:convert';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:ktxhttp/com/ktx/net/paser.dart';
import 'multipartfile_covert.dart';


class NetManager {
  String _baseUrl;
  Dio _dio;
  int _defaultConnectTimeout = 5000;
  int _defaultReceiveTimeout = 100000;
  String _contentType = "application/json";
  String _accept = "application/json";
  Parser _parser;
  MultiPartFileConverter _converter;
  static NetManager _instance;

  static NetManager getInstance() => _instance;

  NetManager._internal() {
    _initDio();
  }

  _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: "",
      connectTimeout: _defaultConnectTimeout,
      receiveTimeout: _defaultReceiveTimeout,
      // 5s
      headers: {
        "Content-Type": _contentType,
        "Accept": _accept,
      },
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ));
  }

  ///设置代理
  _setProxy(String ip, String port) {
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.findProxy = (url) {
        return "PROXY $ip:$port";
      };
    };
  }

  get<T>(String path,
      {Map<String, dynamic> params,
        String baseUrl,
        Options options,
        CancelToken cancelToken,
        ProgressCallback onReceiveProgress, Parser parser}) async {
    String httpBaseUrl = baseUrl ?? _baseUrl;
    Response response = await _dio.get(httpBaseUrl + path,
        queryParameters: params,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress);

    if (_parser == null && parser == null) {
      throw Exception('没有配置数据解析器...');
    }
    return _parser ?? parser.parse<T>(response);
  }


  post<T>(String path, dynamic requestBody,
      {String baseUrl, Map<String, dynamic> queryParameters,
        Options options,
        CancelToken cancelToken,
        ProgressCallback onSendProgress,
        ProgressCallback onReceiveProgress, Parser parser}) async {
    Response response = await _dio.post(
        baseUrl ?? _baseUrl + path,
        data: requestBody,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress
    );

    if (_parser == null && parser == null) {
      throw Exception('没有配置数据解析器...');
    }
    return _parser ?? parser.parse<T>(response);
  }


  upload<T>(String path, List<dynamic>files, { Map<String,
      dynamic> fields, String baseUrl, Converter converter }) async {
    if (files == null || files.length == 0) {
      print('upload 上传文件集合为空！！');
      return;
    }
    var formData = FormData();
    if (fields != null) {
      formData.fields.add(MapEntry('content', jsonEncode(fields)));
    }

    List<MultipartFile> list = await Future.wait(files.map((e) {
      if (_converter == null && converter == null) {
        throw Exception('没有配置MultipartFile转换器...');
      }
      return _converter ?? converter.convert(e);
    })).then((dataList) {
      return dataList;
    });

    list.forEach((value) {
      formData.files.add(MapEntry('files', value));
    });

    Response response = await _dio.post(baseUrl ?? _baseUrl + path,
      data: formData,
    );
    return _parser.parse<T>(response);
  }


}

class NetBuilder {


  String _ip;
  String _port;
  int _connectTimeout;
  int _receiveTimeout;
  Map<String,dynamic> _headers;
  Interceptor _interceptor;
  Parser _parser;
  MultiPartFileConverter _converter;


  ///设置代理
  NetBuilder setProxy(String ip, String port) {
    _ip = ip;
    _port = port;
    return this;
  }

  ///设置连接超时时长
  NetBuilder setConnectTimeout(int milliseconds) {
    _connectTimeout = milliseconds;
    return this;
  }

  ///设置接收超时时长
  NetBuilder setReceiveTimeout(int milliseconds) {
    _receiveTimeout = milliseconds;
    return this;
  }

  ///设置Header
  NetBuilder setHeaders(Map<String, dynamic> headersMap) {
    _headers = headersMap;
    return this;
  }

  ///添加拦截器
  NetBuilder addInterceptor(Interceptor interceptor) {
    _interceptor= interceptor;
    return this;
  }


  ///添设置MultiPartFile转换器
  NetBuilder setMultiPartFileConverter(MultiPartFileConverter converter) {
    _converter = converter;
    return this;
  }

  ///添设置数据解析器
  NetBuilder setParser(Parser parser) {
    _parser = parser;
    return this;
  }

  ///构建
   build(String baseUrl, {Parser parser, MultiPartFileConverter converter}) {

    if (NetManager._instance ==null) {
      NetManager._instance = NetManager._internal();
    }
    NetManager net =  NetManager._instance;

    if (_ip != null && _port != null) {
      net._setProxy(_ip, _port);
    }

    if(_connectTimeout!=null){
      net._dio.options.connectTimeout = _connectTimeout;
    }

    if(_receiveTimeout!=null){
      net._dio.options.receiveTimeout = _receiveTimeout;
    }

    if(_headers!=null){
      _headers.forEach((key, value) {
        net._dio.options.headers[key] = value;
      });

    }

    if(_interceptor!=null){
      net._dio.interceptors.add(_interceptor);
    }

    net._converter =converter?? _converter;
    net._parser = parser??_parser;
    net._baseUrl = baseUrl;
  }
}
