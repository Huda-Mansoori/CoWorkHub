import 'dart:convert';
import 'package:http/http.dart' as http;

class MemberApi {
  //1- backend address
  final String baseUrl = 'http://localhost:8080/api/members';

  //2- get all members
  Future<List<dynamic>> getMembers() async{
    //2.1- send get request to spring boot
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode== 200){
      return jsonDecode(response.body);/*Take the data received from 
    Spring Boot, convert it into Dart data, and send it back to the 
    function that requested it */
    } else{
      throw Exception("failed to load members");
    }
    

  }
}