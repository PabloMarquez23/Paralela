import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

// ==============================================================================
// 🔐 PANTALLA DE AUTENTICACIÓN
// ==============================================================================
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
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Por favor, ingresa tu correo y contraseña.')));
      return;
    }

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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

// ==============================================================================
// 🏠 PANTALLA PRINCIPAL: FEED DE LA RED SOCIAL WITH INTERACTION WIDGET
// ==============================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _posts = [];
  bool _isLoadingFeed = true;

  @override
  void initState() {
    super.initState();
    _cargarFeedSocial();
  }

  Future<void> _cargarFeedSocial() async {
    if (!mounted) return;
    setState(() => _isLoadingFeed = true);
    try {
      final response = await http.get(Uri.parse('http://192.168.18.18:8080/api/posts'));
      if (response.statusCode == 200) {
        setState(() {
          _posts = json.decode(utf8.decode(response.bodyBytes));
          _isLoadingFeed = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingFeed = false);
    }
  }

  void _mostrarComentarios(BuildContext context, String postId) {
    final TextEditingController commentController = TextEditingController();
    List<dynamic> comments = [];
    bool isLoadingComments = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            Future<void> cargarComentariosInterno() async {
              try {
                final res = await http.get(Uri.parse('http://192.168.18.18:8080/api/interactions/comments/post/$postId'));
                if (res.statusCode == 200) {
                  setModalState(() {
                    comments = json.decode(utf8.decode(res.bodyBytes));
                    isLoadingComments = false;
                  });
                }
              } catch (e) {
                setModalState(() => isLoadingComments = false);
              }
            }

            if (isLoadingComments) {
              cargarComentariosInterno();
            }

            Future<void> enviarComentarioInterno() async {
              if (commentController.text.trim().isEmpty) return;
              final user = Supabase.instance.client.auth.currentUser;
              if (user == null) return;

              try {
                final response = await http.post(
                  Uri.parse('http://192.168.18.18:8080/api/interactions/comments'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({
                    'postId': postId,
                    'userId': user.id,
                    'content': commentController.text.trim(),
                  }),
                );

                if (response.statusCode == 200 || response.statusCode == 201) {
                  commentController.clear();
                  setModalState(() => isLoadingComments = true);
                }
              } catch (e) {
                print("Error al inyectar comentario: $e");
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20, left: 16, right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 10),
                  const Text('Comentarios del Laboratorio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const Divider(),
                  Container(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
                    child: isLoadingComments
                        ? const Center(child: CircularProgressIndicator())
                        : comments.isEmpty
                            ? const Padding(padding: EdgeInsets.all(20), child: Text('No hay aportes académicos aún. ¡Escribe el primero!', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: comments.length,
                                itemBuilder: (context, i) {
                                  final c = comments[i];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blueGrey[100],
                                      child: Text((c['username'] ?? 'E').toString().substring(0,1).toUpperCase()),
                                    ),
                                    title: Text(c['username'] ?? 'Estudiante', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    subtitle: Text(c['content'] ?? ''),
                                  );
                                },
                              ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: const InputDecoration(hintText: 'Añadir aporte técnico o consulta...', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send, color: Color(0xFF1E3A8A)),
                          onPressed: enviarComentarioInterno,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UPSGlam 3.0 - Comunidad', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargarFeedSocial),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          )
        ],
      ),
      body: _isLoadingFeed
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(child: Text('No hay publicaciones en el feed todavía. ¡Sé el primero! 🚀'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    final String postId = post['id'].toString();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1E3A8A),
                              child: Text(
                                (post['username'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(post['username'] ?? 'Estudiante UPS', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(post['createdAt'] != null ? post['createdAt'].toString().substring(0, 16).replaceAll('T', ' ') : ''),
                          ),
                          if (post['description'] != null && post['description'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(post['description'], style: const TextStyle(fontSize: 15)),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text('Original', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    Image.network(post['imageUrl'], height: 180, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 180, color: Colors.grey[300])),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text('Resultado GPU', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                                    Image.network(post['processedUrl'] ?? post['imageUrl'], height: 180, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 180, color: Colors.grey[300])),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // 🎯 ACCIONES UNIFICADAS DEL FEED: BOTÓN LIKES DINÁMICO Y COMENTARIOS
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Row(
                              children: [
                                if (currentUser != null)
                                  LikeButtonWidget(postId: postId, userId: currentUser.id),
                                const SizedBox(width: 16),
                                TextButton.icon(
                                  onPressed: () => _mostrarComentarios(context, postId),
                                  icon: const Icon(Icons.comment_outlined, color: Color(0xFF1E3A8A)),
                                  label: const Text('Comentarios', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
          if (image != null) {
            if (!mounted) return;
            Navigator.push(context, MaterialPageRoute(builder: (context) => FilterScreen(selectedImage: image))).then((_) => _cargarFeedSocial());
          }
        },
        backgroundColor: const Color(0xFF1E3A8A),
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('Nueva Foto', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ==============================================================================
// ❤️ WIDGET ENCAPSULADO DE REACCIONES (MANEJO EN CALIENTE DE LIKES)
// ==============================================================================
class LikeButtonWidget extends StatefulWidget {
  final String postId;
  final String userId;
  const LikeButtonWidget({super.key, required this.postId, required this.userId});

  @override
  State<LikeButtonWidget> createState() => _LikeButtonWidgetState();
}

class _LikeButtonWidgetState extends State<LikeButtonWidget> {
  int _likesCount = 0;
  bool _isLikedByMe = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosReaccion();
  }

  Future<void> _cargarDatosReaccion() async {
    try {
      // 1. Cargar el contador reactivo
      final countRes = await http.get(Uri.parse('http://192.168.18.18:8080/api/interactions/likes/count/${widget.postId}'));
      // 2. Verificar el estado del estudiante actual
      final checkRes = await http.get(Uri.parse('http://192.168.18.18:8080/api/interactions/likes/check?postId=${widget.postId}&userId=${widget.userId}'));

      if (countRes.statusCode == 200 && checkRes.statusCode == 200) {
        if (mounted) {
          setState(() {
            _likesCount = json.decode(countRes.body)['likesCount'] ?? 0;
            _isLikedByMe = json.decode(checkRes.body)['liked'] ?? false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike() async {
    // Optimistic UI Update: Cambia el estado visual de inmediato para dar fluidez
    setState(() {
      if (_isLikedByMe) {
        _isLikedByMe = false;
        _likesCount--;
      } else {
        _isLikedByMe = true;
        _likesCount++;
      }
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.18.18:8080/api/interactions/likes/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'postId': widget.postId,
          'userId': widget.userId,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        // Si el backend rebotó la petición, revertimos el cambio visual por seguridad
        _cargarDatosReaccion();
      }
    } catch (e) {
      _cargarDatosReaccion();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            _isLikedByMe ? Icons.favorite : Icons.favorite_border,
            color: _isLikedByMe ? Colors.red : Colors.grey[600],
          ),
          onPressed: _toggleLike,
        ),
        const SizedBox(width: 4),
        Text(
          '$_likesCount',
          style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}

// ==============================================================================
// 🎨 PANTALLA DE PROCESAMIENTO Y COMPARTICIÓN
// ==============================================================================
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
  bool _isPublishing = false;
  Uint8List? _imagenProcesadaBytes; 
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarFiltrosConSeguridad(); 
  }

  Future<void> _cargarFiltrosConSeguridad() async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final response = await http.get(Uri.parse('http://192.168.18.18:8080/api/metrics/available-filters')).timeout(
        const Duration(seconds: 4),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _filtrosDescubiertos = json.decode(response.body);
            _isLoadingFilters = false;
          });
          return;
        }
      }
    } catch (e) {
      print("⚠️ Servidor no respondió a tiempo, aplicando catálogo local: $e");
    }

    if (mounted && _filtrosDescubiertos.isEmpty) {
      setState(() {
        _filtrosDescubiertos = {
          "CONVOLUCION_MANUAL": ["15x15", "150x150", "350x350"]
        };
        _isLoadingFilters = false;
      });
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
      
      request.fields['filter'] = _filtroSeleccionado!;
      request.fields['mask_size'] = _mascaraSeleccionada!;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          _imagenProcesadaBytes = response.bodyBytes; 
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ ¡Convolución completada en núcleos CUDA!'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('Error del clúster: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _publicarEnComunidad() async {
    if (_imagenProcesadaBytes == null) return;
    setState(() => _isPublishing = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String originalFileName = 'original_$timestamp.jpg';
      final String processedFileName = 'processed_$timestamp.jpg';

      final File originalFile = File(widget.selectedImage.path);
      await supabase.storage.from('original-images').upload(originalFileName, originalFile);
      final String originalUrl = supabase.storage.from('original-images').getPublicUrl(originalFileName);

      await supabase.storage.from('processed-images').uploadBinary(processedFileName, _imagenProcesadaBytes!);
      final String processedUrl = supabase.storage.from('processed-images').getPublicUrl(processedFileName);

      final response = await http.post(
        Uri.parse('http://192.168.18.18:8080/api/posts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': user.id,
          'imageUrl': originalUrl,
          'processedUrl': processedUrl,
          'description': _descriptionController.text.trim()
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 ¡Publicado en el Feed Social con éxito!'), backgroundColor: Colors.green));
          Navigator.pop(context); 
        }
      } else {
        throw Exception('Fallo al guardar en el backend social: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Fallo al publicar: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> opcionesMascaras = [];
    if (_filtroSeleccionado != null && _filtrosDescubiertos.containsKey(_filtroSeleccionado)) {
      opcionesMascaras = List<String>.from(_filtrosDescubiertos[_filtroSeleccionado]);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Filtro Convolución Real', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1E3A8A), iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
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
                  
                  _isLoadingFilters 
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        children: [
                          DropdownButton<String>(
                            hint: const Text('Selecciona Filtro de Python'),
                            value: _filtroSeleccionado,
                            isExpanded: true,
                            items: _filtrosDescubiertos.keys.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                            onChanged: (val) => setState(() { _filtroSeleccionado = val; _mascaraSeleccionada = null; }),
                          ),
                          const SizedBox(height: 16),
                          DropdownButton<String>(
                            hint: const Text('Selecciona Máscara de tu Práctica'),
                            value: _mascaraSeleccionada,
                            isExpanded: true,
                            items: opcionesMascaras.map((m) => DropdownMenuItem(value: m, child: Text("Máscara $m"))).toList(),
                            onChanged: (val) => setState(() => _mascaraSeleccionada = val),
                          ),
                        ],
                      ),
                      
                  const SizedBox(height: 30),
                  _isProcessing
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _procesarEnGPU,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                          child: const Text('PROCESAR EN GPU RECONFIGURABLE 🚀', style: TextStyle(color: Colors.white)),
                        ),
                  
                  if (_imagenProcesadaBytes != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(thickness: 2),
                    ),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: '¿Qué estás probando en este laboratorio?',
                        hintText: 'Escribe una descripción para tus compañeros...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _isPublishing
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            onPressed: _publicarEnComunidad,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            icon: const Icon(Icons.share, color: Colors.white),
                            label: const Text('COMPARTIR EN COMUNIDAD UPS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                  ],
                ],
              ),
            ),
    );
  }
}