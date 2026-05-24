import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Asegúrate de tener este import para los MediaType
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://rslxsrsrquardptnjvgl.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJzbHhzcnNycXVhcmRwdG5qdmdsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzOTYzNzgsImV4cCI6MjA5NDk3MjM3OH0.ZZm7a2lvzGB_9CrLbpjG_Bhd0tAQ-xysqtKN2soOwuk', 
  );
  runApp(const UPSGlamApp());
}

class UPSGlamApp extends StatelessWidget {
  const UPSGlamApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPSGlam 3.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const LoginScreen(), 
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (response.user != null && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔒 Credenciales incorrectas.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt_rounded, size: 60, color: Color(0xFF1E3A8A)),
                  const SizedBox(height: 16),
                  const Text('UPSGlam 3.0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 24),
                  TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder())),
                  const SizedBox(height: 24),
                  _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _signIn, child: const Text('Iniciar Sesión')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UPSGlam 3.0', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1E3A8A)),
      body: const Center(child: Text('Presiona el botón para procesar una foto real en la GPU 🚀')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
          if (image != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => FilterScreen(selectedImage: image)));
          }
        },
        backgroundColor: const Color(0xFF1E3A8A),
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('Nueva Foto', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class FilterScreen extends StatefulWidget {
  final XFile selectedImage;
  const FilterScreen({super.key, required this.selectedImage});
  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  Map<String, dynamic> _filtrosDescubiertos = {};
  String? _filtroSeleccionado;
  String? _mascaraSeleccionada;
  bool _isLoadingFilters = true;
  bool _isProcessing = false;
  Uint8List? _imagenProcesadaBytes; 

  @override
  void initState() {
    super.initState();
    _cargarFiltrosDesdeBackend();
  }

  Future<void> _cargarFiltrosDesdeBackend() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.18.18:8080/api/metrics/available-filters'));
      if (response.statusCode == 200) {
        setState(() {
          _filtrosDescubiertos = json.decode(response.body);
          _isLoadingFilters = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingFilters = false);
    }
  }

  void _procesarEnGPU() async {
    if (_filtroSeleccionado == null || _mascaraSeleccionada == null) return;
    setState(() => _isProcessing = true);

    try {
      print('🚀 Transmitiendo imagen real por bloques de bytes a la laptop...');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.18.18:8080/api/metrics/process-image'),
      );

      // 1. Adjuntar archivo de imagen binario explícito
      var stream = http.ByteStream(widget.selectedImage.openRead());
      var length = await widget.selectedImage.length();
      var multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: widget.selectedImage.name,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
      
      // 2. 🎯 SOLUCIÓN DEFINITIVA: Forzar la creación de partes de texto explícitas compatibles con @RequestPart
      request.files.add(
        http.MultipartFile.fromString(
          'filter',
          _filtroSeleccionado!,
          contentType: MediaType('text', 'plain'),
        ),
      );
      
      request.files.add(
        http.MultipartFile.fromString(
          'mask_size',
          _mascaraSeleccionada!,
          contentType: MediaType('text', 'plain'),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          _imagenProcesadaBytes = response.bodyBytes; 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ ¡Convolución completada en núcleos CUDA!'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Error del clúster: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> opcionesMascaras = [];
    if (_filtroSeleccionado != null && _filtrosDescubiertos.containsKey(_filtroSeleccionado)) {
      opcionesMascaras = List<String>.from(_filtrosDescubiertos[_filtroSeleccionado]);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Filtro Convolución Real', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1E3A8A), iconTheme: const IconThemeData(color: Colors.white)),
      body: _isLoadingFilters
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Original', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Image.file(File(widget.selectedImage.path), height: 160, fit: BoxFit.cover),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Resultado GPU', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            const SizedBox(height: 6),
                            _imagenProcesadaBytes != null
                                ? Image.memory(_imagenProcesadaBytes!, height: 160, fit: BoxFit.cover)
                                : Container(height: 160, color: Colors.grey[300], child: const Icon(Icons.bolt, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DropdownButton<String>(
                    hint: const Text('Selecciona Filtro de Python'),
                    value: _filtroSeleccionado,
                    isExpanded: _filtroSeleccionado != null,
                    items: _filtrosDescubiertos.keys.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                    onChanged: (val) => setState(() { _filtroSeleccionado = val; _mascaraSeleccionada = null; }),
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    hint: const Text('Selecciona Máscara de tu Práctica'),
                    value: _mascaraSeleccionada,
                    isExpanded: _mascaraSeleccionada != null,
                    items: opcionesMascaras.map((m) => DropdownMenuItem(value: m, child: Text("Máscara $m"))).toList(),
                    onChanged: (val) => setState(() => _mascaraSeleccionada = val),
                  ),
                  const SizedBox(height: 30),
                  _isProcessing
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(onPressed: _procesarEnGPU, child: const Text('PROCESAR EN GPU RECONFIGURABLE 🚀')),
                ],
              ),
            ),
    );
  }
}