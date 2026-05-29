import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // 🎯 Para dar formato limpio a fecha y hora
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
      theme: ThemeData(
        primaryColor: const Color(0xFF1E3A8A),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        useMaterial3: true,
      ),
      home: const LoginScreen(), 
    );
  }
}

// ==============================================================================
// 🔐 PANTALLA DE AUTENTICACIÓN (LOGIN)
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔒 Credenciales incorrectas o usuario no registrado.')));
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
                  TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Correo Institucional', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder())),
                  const SizedBox(height: 24),
                  _isLoading 
                      ? const CircularProgressIndicator() 
                      : Column(
                          children: [
                            ElevatedButton(
                              onPressed: _signIn, 
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), minimumSize: const Size(200, 45)),
                              child: const Text('Iniciar Sesión', style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                              },
                              child: const Text('¿No tienes cuenta? Regístrate aquí', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
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
// 📝 PANTALLA DE REGISTRO
// ==============================================================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Todos los campos son obligatorios.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username}, 
      );

      if (response.user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 ¡Registro completado! Ya puedes iniciar sesión.'), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Error en el registro.'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      appBar: AppBar(title: const Text('Registro Estudiante', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1E3A8A), iconTheme: const IconThemeData(color: Colors.white)),
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
                  const Text('Nueva Cuenta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 20),
                  TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder())),
                  const SizedBox(height: 24),
                  _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _signUp, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Registrarme', style: TextStyle(color: Colors.white))),
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
// 🏠 NAVEGADOR PRINCIPAL (MÉTRICAS REMOVIDAS, BADGE DE ALERTAS AGREGADO)
// ==============================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<_FeedTabState> _feedKey = GlobalKey();
  final GlobalKey<_NotificationsTabState> _notificationsKey = GlobalKey();
  final GlobalKey<_ProfileTabState> _profileKey = GlobalKey();
  
  bool _hasNewNotifications = false;

  @override
  void initState() {
    super.initState();
    _revisarAlertasPendientes();
  }

  Future<void> _revisarAlertasPendientes() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      // 🎯 CONDICIÓN MEJORADA: El punto rojo solo se dibuja si existen notificaciones con is_read = false
      final res = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false)
          .limit(1);
      
      if (mounted) {
        setState(() {
          _hasNewNotifications = (res as List).isNotEmpty;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _tabs = [
      FeedTab(key: _feedKey),
      NotificationsTab(key: _notificationsKey),
      ProfileTab(key: _profileKey),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) _feedKey.currentState?._cargarFeedSocial();
          if (index == 1) {
            setState(() => _hasNewNotifications = false); // Borra el aviso visual al instante
            _notificationsKey.currentState?._cargarNotificaciones();
          }
          if (index == 2) _profileKey.currentState?._loadProfileAndPosts();
        },
        selectedItemColor: const Color(0xFF1E3A8A),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.dynamic_feed), label: 'Comunidad'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_hasNewNotifications)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                      constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                    ),
                  )
              ],
            ),
            label: 'Alertas',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
      floatingActionButton: _currentIndex == 0 
        ? FloatingActionButton.extended(
            onPressed: () async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                if (!mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (context) => FilterScreen(selectedImage: image)))
                    .then((_) => _feedKey.currentState?._cargarFeedSocial());
              }
            },
            backgroundColor: const Color(0xFF1E3A8A),
            icon: const Icon(Icons.add_a_photo, color: Colors.white),
            label: const Text('Nueva Foto', style: TextStyle(color: Colors.white)),
          )
        : null,
    );
  }
}
// ==============================================================================
// 🔔 TAB 2: NOTIFICACIONES ACADÉMICAS (DIRECCIÓN INTELIGENTE A POSTS O PERFILES)
// ==============================================================================
class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});
  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (mounted) setState(() => _isLoading = true);

    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id);

      final response = await Supabase.instance.client
          .from('notifications')
          .select('*, profiles!notifications_source_user_id_fkey(username, bio, id)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications = response as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🎯 REDIRECCIÓN COMPLETA DE ALERTA AL DETALLE DEL POST REAL
  void _navegarAlPost(String? postId) async {
    if (postId == null) return;
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('http://192.168.18.18:8080/api/posts'));
      List<dynamic> all = json.decode(utf8.decode(res.bodyBytes));
      final postTarget = all.firstWhere((p) => p['id'].toString() == postId);

      final profileRes = await Supabase.instance.client.from('profiles').select('username').eq('id', postTarget['userId']).single();
      postTarget['username'] = profileRes['username'];

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Publicación Relacionada')),
              body: SingleChildScrollView(child: _FeedTabState.construirTarjetaPost(context, postTarget, true, Supabase.instance.client.auth.currentUser, null)),
            ),
          ),
        );
      }
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  // 🎯 NUEVA REDIRECCIÓN: Abre el perfil completo del estudiante que te acaba de seguir
  void _verPerfilSeguidor(Map<String, dynamic> perfilRemitente) async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('http://192.168.18.18:8080/api/posts'));
      List<dynamic> all = json.decode(utf8.decode(res.bodyBytes));
      
      // Filtramos únicamente las publicaciones que le pertenecen a ese estudiante
      List<dynamic> studentPosts = all.where((p) => p['userId'].toString().toLowerCase() == perfilRemitente['id'].toString().toLowerCase()).toList();

      for (var p in studentPosts) {
        p['username'] = perfilRemitente['username'];
      }

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: Text('Perfil de @${perfilRemitente['username']}')),
              body: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(backgroundColor: const Color(0xFF1E3A8A), child: Text(perfilRemitente['username'][0].toUpperCase(), style: const TextStyle(color: Colors.white))),
                    title: Text('@${perfilRemitente['username']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(perfilRemitente['bio'] ?? 'Estudiante de Ingeniería en Sistemas.'),
                  ),
                  const Divider(),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
                      itemCount: studentPosts.length,
                      itemBuilder: (context, i) => GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(title: const Text('Detalle de Cómputo')),
                                body: SingleChildScrollView(child: _FeedTabState.construirTarjetaPost(context, studentPosts[i], true, Supabase.instance.client.auth.currentUser, null)),
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(studentPosts[i]['processedUrl'] ?? studentPosts[i]['imageUrl'] ?? '', fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  String _obtenerTextoAlerta(Map<String, dynamic> n) {
    String usuario = n['profiles']?['username'] ?? 'Un estudiante';
    switch (n['type']) {
      case 'LIKE_POST':
        return '❤️ A @$usuario le gustó tu publicación.';
      case 'COMMENT':
        return '💬 @$usuario comentó tu foto.';
      case 'REPLY':
        return '🔄 @$usuario respondió a tu hilo técnico.';
      case 'LIKE_COMMENT':
        return '👍 A @$usuario le gustó tu comentario.';
      case 'NEW_POST':
        return '🚀 @$usuario subió una nueva foto procesada en CUDA.';
      case 'FOLLOW':
        return '🚀 @$usuario comenzó a seguir tus experimentos en CUDA.';
      default:
        return '🔔 Tienes una nueva interacción en UPSGlam.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Alertas Académicas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF1E3A8A)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No tienes interacciones todavía. 🎯'))
              : RefreshIndicator(
                  onRefresh: _cargarNotificaciones,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, idx) {
                      final item = _notifications[idx];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          // Enrutador inteligente según el tipo de interacción de Supabase
                          onTap: () {
                            if (item['type'] == 'FOLLOW') {
                              _verPerfilSeguidor(item['profiles']);
                            } else {
                              _navegarAlPost(item['post_id']?.toString());
                            }
                          },
                          leading: const CircleAvatar(backgroundColor: Color(0xFF1E3A8A), child: Icon(Icons.bolt, color: Colors.white, size: 18)),
                          title: Text(_obtenerTextoAlerta(item), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ==============================================================================
// 📋 TAB 1: FEED SOCIAL REPOTENCIADO (COMPONENTE UNIFICADO Y SEGURO)
// ==============================================================================
class FeedTab extends StatefulWidget {
  const FeedTab({super.key});
  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  List<dynamic> _posts = [];
  List<String> _followingIds = []; 
  bool _isLoadingFeed = true;

  @override
  void initState() {
    super.initState();
    _cargarFeedSocial();
  }

  Future<void> _cargarFeedSocial() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    try {
      final followsRes = await Supabase.instance.client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUser.id);
      
      _followingIds = (followsRes as List).map((f) => f['following_id'].toString()).toList();

      final response = await http.get(Uri.parse('http://192.168.18.18:8080/api/posts'));
      if (response.statusCode == 200 && mounted) {
        List<dynamic> postsData = json.decode(utf8.decode(response.bodyBytes));
        
        for (var post in postsData) {
          try {
            final profileRes = await Supabase.instance.client
                .from('profiles')
                .select('username')
                .eq('id', post['userId'])
                .single();
            post['username'] = profileRes['username'];
          } catch (_) {
            post['username'] = 'Estudiante UPS';
          }
        }

        setState(() {
          _posts = postsData;
          _isLoadingFeed = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingFeed = false);
    }
  }

  void _confirmarDejarDeSeguir(String followingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dejar de seguir'),
        content: const Text('¿Estás seguro de que quieres dejar de seguir a este estudiante? Ya no recibirás alertas de sus kernels CUDA.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final currentUser = Supabase.instance.client.auth.currentUser;
              if (currentUser != null) {
                await Supabase.instance.client
                    .from('follows')
                    .delete()
                    .eq('follower_id', currentUser.id)
                    .eq('following_id', followingId);
                
                setState(() {
                  _followingIds.remove(followingId);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Has dejado de seguir a este estudiante.')));
              }
            },
            child: const Text('Confirmar', style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _seguirEstudiante(String followingId) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    try {
      final res = await http.post(
        Uri.parse('http://192.168.18.18:8080/api/profiles/follow'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'followerId': currentUser.id, 'followingId': followingId})
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _followingIds.add(followingId);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 ¡Ahora sigues a este estudiante! Recibirás alertas de sus fotos.'), backgroundColor: Colors.green));
      }
    } catch (e) {}
  }

  static Widget construirTarjetaPost(BuildContext context, Map<String, dynamic> post, bool yaLoSigo, dynamic currentUser, VoidCallback? onFollowAction) {
    String fechaFormateada = "Reciente";
    if (post['createdAt'] != null) {
      try {
        DateTime dt = DateTime.parse(post['createdAt']);
        fechaFormateada = DateFormat('dd/MM/yyyy - HH:mm').format(dt);
      } catch (e) {}
    }

    String displayUsername = post['username'] ?? 'Estudiante UPS';
    String initialLetter = displayUsername.isNotEmpty ? displayUsername[0].toUpperCase() : 'U';

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(backgroundColor: const Color(0xFF1E3A8A), child: Text(initialLetter, style: const TextStyle(color: Colors.white))),
            title: Text(displayUsername, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(fechaFormateada, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: currentUser != null && currentUser.id != post['userId']
                ? yaLoSigo 
                    ? InkWell(
                        onTap: onFollowAction, 
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Siguiendo', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                      )
                    : TextButton.icon(
                        onPressed: onFollowAction,
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Seguir', style: TextStyle(fontSize: 12)),
                      )
                : null,
          ),
          if (post['description'] != null && post['description'].toString().isNotEmpty)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), child: Text(post['description'])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(child: Image.network(post['imageUrl'] ?? '', height: 180, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(height: 180, color: Colors.grey[300]))),
                const SizedBox(width: 4),
                Expanded(child: Image.network(post['processedUrl'] ?? '', height: 180, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(height: 180, color: Colors.grey[300]))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (currentUser != null) LikeButtonWidget(key: ValueKey('like_${post['id']}'), postId: post['id'].toString(), userId: currentUser.id),
                    const SizedBox(width: 16),
                    const Icon(Icons.comment_outlined, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Discusión', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    String filtroAmigable = post['appliedMask'] != null && post['appliedMask'].toString().contains('71') || post['appliedMask'].toString().contains('141')
                        ? "Realce de Bordes de Alta Potencia (High Boost)"
                        : "Filtro de Desenfoque Suave (Convolución Manual)";
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Rendimiento de Cómputo'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Filtro Utilizado:\n$filtroAmigable'),
                            const SizedBox(height: 8),
                            Text('Máscara: ${post['appliedMask'] ?? 'AUTO'}'),
                            const SizedBox(height: 8),
                            Text('Tiempo: ${post['kernelTimeMs'] ?? '0.0'} ms'),
                          ],
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
                  icon: const Icon(Icons.info_outline, size: 14, color: Colors.white),
                  label: const Text('Info GPU', style: TextStyle(fontSize: 11, color: Colors.white)),
                )
              ],
            ),
          ),
          CommentSectionWidget(key: ValueKey('comments_${post['id']}'), postId: post['id'].toString()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Comunidad UPSGlam', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1E3A8A)),
      body: _isLoadingFeed 
          ? const Center(child: CircularProgressIndicator()) 
          : _posts.isEmpty
              ? const Center(child: Text('No hay publicaciones todavía. 🚀'))
              : ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, i) {
                    final post = _posts[i];
                    bool yaLoSigo = _followingIds.contains(post['userId'].toString());
                    return construirTarjetaPost(
                      context, 
                      post, 
                      yaLoSigo, 
                      currentUser, 
                      () => yaLoSigo ? _confirmarDejarDeSeguir(post['userId'].toString()) : _seguirEstudiante(post['userId'].toString())
                    );
                  },
                ),
    );
  }
}

// ==============================================================================
// 👤 TAB 3: MI PERFIL (ABRIR DETALLES E HISTORIAL DE PROCESAMIENTO)
// ==============================================================================
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key}); 
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  List<dynamic> _myPosts = [];
  bool _loadingMyFeed = true;
  String _userBio = "¡Hola! Estoy usando el clúster paralelo de UPSGlam.";
  String _username = "Cargando...";

  @override
  void initState() {
    super.initState();
    _loadProfileAndPosts();
  }

  Future<void> _loadProfileAndPosts() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (mounted) setState(() => _loadingMyFeed = true);
    try {
      final profileRes = await http.get(Uri.parse('http://192.168.18.18:8080/api/profiles/${user.id}'));
      if (profileRes.statusCode == 200) {
        final profData = json.decode(utf8.decode(profileRes.bodyBytes));
        _userBio = profData['bio'] ?? _userBio;
        _username = profData['username'] ?? "Estudiante";
      }

      final res = await http.get(Uri.parse('http://192.168.18.18:8080/api/posts'));
      if (res.statusCode == 200 && mounted) {
        final List<dynamic> all = json.decode(utf8.decode(res.bodyBytes));
        setState(() {
          _myPosts = all.where((p) => p['userId'].toString().toLowerCase() == user.id.toLowerCase()).toList();
          _loadingMyFeed = false;
        });
      }
    } catch (e) { if (mounted) setState(() => _loadingMyFeed = false); }
  }

  void _verPublicacionDetallada(Map<String, dynamic> post) {
    post['username'] = _username; 
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Mi Publicación CUDA')),
          body: SingleChildScrollView(child: _FeedTabState.construirTarjetaPost(context, post, true, Supabase.instance.client.auth.currentUser, null)),
        ),
      ),
    );
  }

  Future<void> _cerrarSesionMaster() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
      }
    } catch (_) {}
  }

  void _editarBiografia() {
    final controller = TextEditingController(text: _userBio);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizar Descripción Perfil'),
        content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Escribe tu nueva biografía académica...")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null && controller.text.trim().isNotEmpty) {
                await http.put(Uri.parse('http://192.168.18.18:8080/api/profiles/update-bio'), headers: {'Content-Type': 'application/json'}, body: json.encode({'userId': user.id, 'bio': controller.text.trim()}));
                setState(() => _userBio = controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text('Mi Espacio: $_username'), actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: _cerrarSesionMaster)]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(radius: 30, backgroundColor: const Color(0xFF1E3A8A), child: Text(_username.isNotEmpty ? _username[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.email ?? '', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(_userBio, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.black87)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit, color: Color(0xFF1E3A8A)), onPressed: _editarBiografia)
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _loadingMyFeed 
              ? const Center(child: CircularProgressIndicator())
              : _myPosts.isEmpty 
                ? const Center(child: Text('Aún no has compartido publicaciones relacionales.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
                    itemCount: _myPosts.length,
                    itemBuilder: (context, i) => GestureDetector(
                      onTap: () => _verPublicacionDetallada(_myPosts[i]), 
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(_myPosts[i]['processedUrl'] ?? _myPosts[i]['imageUrl'] ?? '', fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.grey)),
                      ),
                    ),
                  ),
          )
        ],
      ),
    );
  }
}

// ==============================================================================
// ❤️ WIDGET COMPONENTE LIKES POST
// ==============================================================================
class LikeButtonWidget extends StatefulWidget {
  final String postId;
  final String userId;
  const LikeButtonWidget({super.key, required this.postId, required this.userId});
  @override
  State<LikeButtonWidget> createState() => _LikeButtonWidgetState();
}

class _LikeButtonWidgetState extends State<LikeButtonWidget> {
  int _count = 0;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final resC = await http.get(Uri.parse('http://192.168.18.18:8080/api/interactions/likes/count/${widget.postId}'));
      final resL = await http.get(Uri.parse('http://192.168.18.18:8080/api/interactions/likes/check?postId=${widget.postId}&userId=${widget.userId}'));
      if (mounted) {
        setState(() {
          _count = json.decode(resC.body)['likesCount'] ?? 0;
          _liked = json.decode(resL.body)['liked'] ?? false;
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(_liked ? Icons.favorite : Icons.favorite_border, color: Colors.red), 
          onPressed: () async {
            setState(() { _liked = !_liked; _liked ? _count++ : _count--; });
            await http.post(Uri.parse('http://192.168.18.18:8080/api/interactions/likes/toggle'), headers: {'Content-Type': 'application/json'}, body: json.encode({'postId': widget.postId, 'userId': widget.userId}));
          }
        ),
        Text('$_count', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ==============================================================================
// 💬 WIDGET COMPONENTE COMENTARIOS RECURSIVOS (LIKES PERSISTENTES Y CONFIGURADOS)
// ==============================================================================
class CommentSectionWidget extends StatefulWidget {
  final String postId;
  const CommentSectionWidget({super.key, required this.postId});
  @override
  State<CommentSectionWidget> createState() => _CommentSectionWidgetState();
}

class _CommentSectionWidgetState extends State<CommentSectionWidget> {
  List<dynamic> _commentTree = [];
  final _commentController = TextEditingController();
  String? _replyingToCommentId;
  String? _replyingToUsername;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;

      // 1. Traemos los comentarios con su perfil relacional
      final response = await Supabase.instance.client
          .from('comments')
          .select('*, profiles(username)')
          .eq('post_id', widget.postId)
          .order('created_at', ascending: true);

      final List<dynamic> rawComments = response as List<dynamic>;

      List<dynamic> roots = [];
      Map<String, List<dynamic>> mappedReplies = {};

      for (var c in rawComments) {
        c['username'] = c['profiles']?['username'] ?? 'Estudiante';
        c['replies'] = [];
        
        String commentId = c['id'].toString();

        // 2. 🎯 CORREGIDO: Conteo limpio compatible con el SDK sin invocar 'FetchOptions'
        final likesRes = await Supabase.instance.client
            .from('comment_likes')
            .select('id')
            .eq('comment_id', commentId);
            
        c['likesCount'] = (likesRes as List).length;

        // 3. Verificar si el usuario actual le dio like
        if (currentUser != null) {
          final userLikeRes = await Supabase.instance.client
              .from('comment_likes')
              .select('id')
              .eq('comment_id', commentId)
              .eq('user_id', currentUser.id);
          c['likedByCurrentUser'] = (userLikeRes as List).isNotEmpty;
        } else {
          c['likedByCurrentUser'] = false;
        }

        if (c['parent_comment_id'] == null) {
          roots.add(c);
        } else {
          String parentId = c['parent_comment_id'].toString();
          mappedReplies.putIfAbsent(parentId, () => []).add(c);
        }
      }

      void assembleTree(List<dynamic> currentLevel) {
        for (var parent in currentLevel) {
          String pid = parent['id'].toString();
          if (mappedReplies.containsKey(pid)) {
            parent['replies'] = mappedReplies[pid];
            assembleTree(parent['replies']);
          }
        }
      }
      assembleTree(roots);

      if (mounted) {
        setState(() {
          _commentTree = roots;
        });
      }
    } catch (e) {
      debugPrint("Error cargando persistencia de hilos: $e");
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      final bodyData = {
        'postId': widget.postId,
        'userId': currentUser.id,
        'content': _commentController.text.trim(),
        'parentCommentId': _replyingToCommentId
      };
      final res = await http.post(
        Uri.parse('http://192.168.18.18:8080/api/interactions/comments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bodyData)
      );
      if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
        _commentController.clear();
        setState(() { _replyingToCommentId = null; _replyingToUsername = null; });
        _loadComments();
      }
    } catch (e) {}
  }

  Future<void> _toggleCommentLike(String commentId) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    try {
      _updateLocalLikeState(_commentTree, commentId);
      await http.post(
        Uri.parse('http://192.168.18.18:8080/api/interactions/comments/likes/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'commentId': commentId, 'userId': currentUser.id}),
      );
    } catch (e) { _loadComments(); }
  }

  void _updateLocalLikeState(List<dynamic> list, String commentId) {
    for (var c in list) {
      if (c['id'].toString() == commentId) {
        setState(() {
          c['likedByCurrentUser'] = !(c['likedByCurrentUser'] ?? false);
          c['likesCount'] = (c['likesCount'] ?? 0) + (c['likedByCurrentUser'] ? 1 : -1);
        });
        return;
      }
      if (c['replies'] != null) _updateLocalLikeState(c['replies'], commentId);
    }
  }

  Widget _buildCommentNode(Map<String, dynamic> comment, {double depth = 0.0}) {
    final List<dynamic> replies = comment['replies'] ?? [];
    final bool isLiked = comment['likedByCurrentUser'] ?? false;
    final int likesCount = comment['likesCount'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 20.0, top: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (depth > 0) Container(width: 2, height: 28, color: Colors.grey[300], margin: const EdgeInsets.only(right: 6, left: 2)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 13),
                        children: [
                          TextSpan(text: '${comment['username'] ?? 'Estudiante'}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: comment['content'] ?? ''),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(onTap: () => setState(() { _replyingToCommentId = comment['id'].toString(); _replyingToUsername = comment['username'] ?? 'Estudiante'; }), child: const Text('Responder', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 14),
                        GestureDetector(onTap: () => _toggleCommentLike(comment['id'].toString()), child: Row(children: [Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 12, color: isLiked ? Colors.red : Colors.grey), const SizedBox(width: 2), Text('$likesCount', style: const TextStyle(fontSize: 11, color: Colors.grey))])),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...replies.map((reply) => _buildCommentNode(reply as Map<String, dynamic>, depth: depth + 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _commentTree.length, itemBuilder: (context, idx) => _buildCommentNode(_commentTree[idx] as Map<String, dynamic>)),
          if (_replyingToCommentId != null) Container(padding: const EdgeInsets.all(6), color: Colors.grey[200], child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Respondiendo a @$_replyingToUsername', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)), IconButton(icon: const Icon(Icons.cancel, size: 14), onPressed: () => setState(() { _replyingToCommentId = null; _replyingToUsername = null; }))])),
          Row(
            children: [
              Expanded(child: TextField(controller: _commentController, decoration: const InputDecoration(hintText: 'Añadir aporte técnico...', isDense: true, border: UnderlineInputBorder()))),
              IconButton(icon: const Icon(Icons.send, size: 20, color: Color(0xFF1E3A8A)), onPressed: _postComment),
            ],
          )
        ],
      ),
    );
  }
}

// ==============================================================================
// 🎨 PANTALLA FILTROS (ESTILO INSTAGRAM: CARRUSEL HORIZONTAL E INFO GPU EN CALIENTE)
// ==============================================================================
class FilterScreen extends StatefulWidget {
  final XFile selectedImage;
  const FilterScreen({super.key, required this.selectedImage});
  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  String? _selectedFilter;
  bool _isProcessing = false;
  bool _isPublishing = false;
  
  Uint8List? _processedImageBytes;
  double _lastKernelTime = 0.0;
  String _lastAppliedMask = "AUTO";
  
  final _descController = TextEditingController();
  final String _ip = '192.168.18.18:8080';

  // Catálogo de filtros con sus respectivos íconos visuales para el carrusel
  // 🎯 CORREGIDO: Cambiado el ícono roto a inglés nativo (Icons.palette_rounded)
  final List<Map<String, dynamic>> _filtrosCarrusel = [
    {
      "nombre": "Desenfoque Suave",
      "id_tecnico": "CONVOLUCION_MANUAL",
      "icono": Icons.blur_on_rounded,
      "descripcion": "Suaviza bordes ruidosos"
    },
    {
      "nombre": "Alta Potencia",
      "id_tecnico": "HIGH_BOOST",
      "icono": Icons.palette_rounded, // 🎯 Ícono corregido en inglés limpio
      "descripcion": "Realza detalles ocultos"
    }
  ];

  void _processImageInGPU(String filtroTecnico) async {
    setState(() {
      _isProcessing = true;
      _processedImageBytes = null; // Limpia vista previa anterior
    });
    
    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://$_ip/api/metrics/process-image'));
      request.files.add(await http.MultipartFile.fromPath('image', widget.selectedImage.path));
      
      request.fields['filter'] = filtroTecnico;
      request.fields['userId'] = Supabase.instance.client.auth.currentUser!.id;
      request.fields['mask_size'] = 'AUTO'; 

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _processedImageBytes = base64Decode(data['imageBytes']);
          _lastKernelTime = (data['kernelTimeMs'] as num).toDouble();
          _lastAppliedMask = data['appliedMask'].toString();
        });
      }
    } catch (e) {
      debugPrint("Error al procesar en clúster: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Fondo gris claro sutil estilo iOS/Instagram
      appBar: AppBar(
        title: const Text('Filtros de Laboratorio', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. ÁREA DE VISUALIZACIÓN MULTIMEDIA (FOTO PRINCIPAL)
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _processedImageBytes != null 
                    ? Image.memory(_processedImageBytes!, fit: BoxFit.contain, width: double.infinity) 
                    : Image.file(File(widget.selectedImage.path), fit: BoxFit.contain, width: double.infinity),
              ),
            ),
          ),

          // INDICADOR DE PROCESAMIENTO EN CALIENTE
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E3A8A))),
                  SizedBox(width: 12),
                  Text('Ejecutando Kernel en Paralelo con CUDA...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                ],
              ),
            ),

          // 2. 🔥 SECCIÓN MAESTRA: CARRUSEL HORIZONTAL ESTILO INSTAGRAM
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Align(alignment: Alignment.centerLeft, child: Text('Efectos Disponibles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey))),
          ),
          Container(
            height: 110,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtrosCarrusel.length,
              itemBuilder: (context, idx) {
                final filtro = _filtrosCarrusel[idx];
                bool esSeleccionado = _selectedFilter == filtro['nombre'];

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedFilter = filtro['nombre']);
                    _processImageInGPU(filtro['id_tecnico']); // Dispara el cómputo atómico al tocar la tarjeta
                  },
                  child: Container(
                    width: 115,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: esSeleccionado ? const Color(0xFF1E3A8A) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: esSeleccionado ? const Color(0xFF1E3A8A) : Colors.grey[300]!, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(filtro['icono'], size: 28, color: esSeleccionado ? Colors.white : const Color(0xFF1E3A8A)),
                        const SizedBox(height: 6),
                        Text(filtro['nombre'], textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: esSeleccionado ? Colors.white : Colors.black87)),
                        const SizedBox(height: 2),
                        Text(filtro['descripcion'], textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: esSeleccionado ? Colors.white70 : Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. CAPA DE ENTRADA METADATOS Y PUBLICACIÓN (SOLO SE ABRE SI SE PROCESÓ UNA IMAGEN)
          if (_processedImageBytes != null)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _descController, 
                        decoration: const InputDecoration(
                          hintText: 'Describe el aporte técnico o análisis de esta imagen...', 
                          isDense: true, 
                          border: UnderlineInputBorder()
                        )
                      ),
                      const SizedBox(height: 12),
                      _isPublishing 
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700], 
                              minimumSize: const Size(double.infinity, 45),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                            ),
                            onPressed: () async {
                              setState(() => _isPublishing = true);
                              try {
                                final user = Supabase.instance.client.auth.currentUser!;
                                final nameTimestamp = '${DateTime.now().millisecondsSinceEpoch}.jpg';
                                
                                final String originalName = 'orig_$nameTimestamp';
                                await Supabase.instance.client.storage.from('original-images').upload(originalName, File(widget.selectedImage.path));
                                final originalUrl = Supabase.instance.client.storage.from('original-images').getPublicUrl(originalName);
                                
                                final String processedName = 'proc_$nameTimestamp';
                                await Supabase.instance.client.storage.from('processed-images').uploadBinary(processedName, _processedImageBytes!);
                                final processedUrl = Supabase.instance.client.storage.from('processed-images').getPublicUrl(processedName);
                                
                                final postRes = await http.post(
                                  Uri.parse('http://$_ip/api/posts'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: json.encode({
                                    'userId': user.id,
                                    'imageUrl': originalUrl,
                                    'processedUrl': processedUrl,
                                    'description': _descController.text.trim(),
                                    'appliedMask': _lastAppliedMask,
                                    'kernelTimeMs': _lastKernelTime
                                  })
                                );

                                if (postRes.statusCode == 200 || postRes.statusCode == 201) {
                                  final Map<String, dynamic> createdPost = json.decode(postRes.body);
                                  String realPostId = createdPost['id'].toString();

                                  final seguidores = await Supabase.instance.client
                                      .from('follows')
                                      .select('follower_id')
                                      .eq('following_id', user.id);
                                  
                                  for (var seg in seguidores as List) {
                                    await Supabase.instance.client.from('notifications').insert({
                                      'user_id': seg['follower_id'],
                                      'source_user_id': user.id,
                                      'type': 'NEW_POST',
                                      'post_id': realPostId,
                                      'is_read': false
                                    });
                                  }
                                }
                                
                                if (mounted) Navigator.pop(context);
                              } catch (e) {} finally {
                                if (mounted) setState(() => _isPublishing = false);
                              }
                            },
                            child: const Text('Publicar en la Comunidad', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                    ],
                  ),
                ),
              ),
            )
          else
            const Expanded(
              flex: 2,
              child: Center(child: Text('Toca un filtro para aplicar convolución en caliente', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
            )
        ],
      ),
    );
  }
}