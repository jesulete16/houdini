import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:houdini/login.dart';
import 'package:houdini/file_packer.dart';
import 'information.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  List<dynamic> playlists = [];
  List<dynamic> favoritePlaylists = [];
  List<dynamic> watchLaterPlaylists = [];
  TextEditingController searchController = TextEditingController();
  List<dynamic> filteredPlaylists = [];
  bool isLoading = true;
  bool showFavorites = false;
  bool showWatchLater = false;
  String currentView = "Todos los discos";

  @override
  void initState() {
    super.initState();
    fetchPlaylists();
    fetchFavorites();
    fetchWatchLater();
  }

  Future<void> fetchPlaylists() async {
    try {
      final response = await supabase.from('playlist').select();
      setState(() {
        playlists = response.isNotEmpty ? response : [];
        filteredPlaylists = playlists;
        isLoading = false;
      });
    } catch (error) {
      print("Error al obtener playlists: $error");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchFavorites() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final response = await supabase
          .from('favorites')
          .select()
          .eq('user_id', user.id);
      setState(() {
        favoritePlaylists = response.map((fav) => fav['playlist_id']).toList();
      });
    } catch (error) {
      print("Error al obtener favoritos: $error");
    }
  }

  Future<void> fetchWatchLater() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final response = await supabase
          .from('watch_later')
          .select()
          .eq('user_id', user.id);
      setState(() {
        watchLaterPlaylists =
            response.map((entry) => entry['playlist_id']).toList();
      });
    } catch (error) {
      print("Error al obtener ver más tarde: $error");
    }
  }

  void toggleFavorite(dynamic playlist) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final isFavorite = favoritePlaylists.contains(playlist['id']);
    setState(() {
      if (isFavorite) {
        favoritePlaylists.remove(playlist['id']);
      } else {
        favoritePlaylists.add(playlist['id']);
      }
    });

    if (isFavorite) {
      await supabase
          .from('favorites')
          .delete()
          .match({'user_id': user.id, 'playlist_id': playlist['id']});
    } else {
      await supabase
          .from('favorites')
          .insert({'user_id': user.id, 'playlist_id': playlist['id']});
    }
  }

  void toggleWatchLater(dynamic playlist) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final isWatchLater = watchLaterPlaylists.contains(playlist['id']);
    setState(() {
      if (isWatchLater) {
        watchLaterPlaylists.remove(playlist['id']);
      } else {
        watchLaterPlaylists.add(playlist['id']);
      }
    });

    if (isWatchLater) {
      await supabase
          .from('watch_later')
          .delete()
          .match({'user_id': user.id, 'playlist_id': playlist['id']});
    } else {
      await supabase
          .from('watch_later')
          .insert({'user_id': user.id, 'playlist_id': playlist['id']});
    }
  }

  void filterPlaylists(String query) {
    setState(() {
      filteredPlaylists = playlists
          .where((playlist) =>
          playlist['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  void logout() async {
    await supabase.auth.signOut();
    setState(() {});
  }
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
        key: _scaffoldKey,  // Add this line
        backgroundColor: appColors['background'],
        appBar: _buildAppBar(user),
        drawer: _buildDrawer(user),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              appColors['background']!,
              Color(0xFF141414),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                currentView.toUpperCase(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: appColors['text'],
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: appColors['accent']!.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: appColors['accent']))
                  : buildPlaylistView(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(User? user) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.menu,
          color: appColors['accent'],
          size: 28,
        ),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      title: Row(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                currentView = "Todos los discos";
                showFavorites = false;
                showWatchLater = false;
                filterPlaylists('');
                searchController.clear();
              });
            },
            child: Text(
              'HOUDINI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: appColors['accent'],
                fontSize: 28,
                letterSpacing: 3,
                shadows: [
                  Shadow(
                    color: appColors['accent']!.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Container(
              height: 40,
              child: TextField(
                controller: searchController,
                style: TextStyle(color: appColors['text']),
                decoration: InputDecoration(
                  hintText: 'Buscar discos...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  filled: true,
                  fillColor: appColors['surface'],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: appColors['accent']!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: appColors['accent']!.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: appColors['accent']!),
                  ),
                ),
                onChanged: filterPlaylists,
              ),
            ),
          ),
        ],
      ),
      actions: _buildAppBarActions(user),
    );
  }

  List<Widget> _buildAppBarActions(User? user) {
    return [
      IconButton(
        icon: Icon(Icons.add_circle_outline, color: Colors.cyan),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FilePackerPage()),
          );
        },
      ),
      if (user != null)
        PopupMenuButton(
          icon: CircleAvatar(
            backgroundColor: Colors.cyan,
            child: Text(
              user.email![0].toUpperCase(),
              style: TextStyle(color: Colors.white),
            ),
          ),
          itemBuilder: (context) =>
          [
            PopupMenuItem(
              child: Text(user.email ?? 'Usuario'),
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Cerrar sesión'),
                ],
              ),
              onTap: logout,
            ),
          ],
        )
      else
        TextButton.icon(
          icon: Icon(Icons.login, color: Colors.cyan),
          label: Text('Iniciar sesión', style: TextStyle(color: Colors.cyan)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
        ),
      SizedBox(width: 8),
    ];
  }

  Widget _buildDrawer(User? user) {
    return Drawer(
      child: Container(
        color: Color(0xFF1A237E), // Dark blue background
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0D47A1), // Darker blue
                    Color(0xFF2196F3), // Lighter blue
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menú',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  if (user != null) ...[
                    SizedBox(height: 10),
                    Text(
                      user.email ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ]
                ],
              ),
            ),
            if (user != null) ...[
              _buildDrawerItem(
                icon: Icons.favorite,
                title: 'Favoritos',
                onTap: () => _updateView("Favoritos", showFav: true),
                color: Colors.white,
              ),
              _buildDrawerItem(
                icon: Icons.watch_later,
                title: 'Ver más tarde',
                onTap: () => _updateView("Ver más tarde", showWatch: true),
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Function() onTap,
    required Color color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
      hoverColor: Colors.white.withOpacity(0.1),
    );
  }

  void _updateView(String view,
      {bool showFav = false, bool showWatch = false}) {
    setState(() {
      currentView = view;
      showFavorites = showFav;
      showWatchLater = showWatch;
    });
  }

  Widget buildPlaylistView() {
    final user = supabase.auth.currentUser;
    List<dynamic> displayPlaylists = showFavorites
        ? playlists.where((p) => favoritePlaylists.contains(p['id'])).toList()
        : showWatchLater
        ? playlists.where((p) => watchLaterPlaylists.contains(p['id'])).toList()
        : filteredPlaylists;

    if (displayPlaylists.isEmpty) {
      return Center(
        child: Text(
          'No hay discos disponibles',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200
            ? 5
            : MediaQuery.of(context).size.width > 800
            ? 4
            : MediaQuery.of(context).size.width > 600
            ? 3
            : 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: displayPlaylists.length,
      itemBuilder: (context, index) {
        final playlist = displayPlaylists[index];
        final isFavorite = favoritePlaylists.contains(playlist['id']);
        final isWatchLater = watchLaterPlaylists.contains(playlist['id']);

        return Card(
          elevation: 8,
          color: appColors['surface'],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: appColors['accent']!.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'playlist-${playlist['id']}',
                      child: Material(
                        color: Colors.transparent,
                        child: MouseRegion(
                          child: TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 200),
                            tween: Tween<double>(begin: 1.0, end: 1.0),
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: InkWell(
                              onTap: () async {
                                final url = playlist['url'];
                                if (url != null && url.isNotEmpty) {
                                  try {
                                    await launchUrl(Uri.parse(url));
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('No se pudo abrir el enlace')),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: appColors['accent']!.withOpacity(0.2),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                                  child: Image.network(
                                    playlist['imagen'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[100],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                                : null,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (user != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.white,
                                ),
                                onPressed: () => toggleFavorite(playlist),
                                tooltip: 'Favorito',
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isWatchLater ? Icons.watch_later : Icons.watch_later_outlined,
                                  color: isWatchLater ? Colors.blue : Colors.white,
                                ),
                                onPressed: () => toggleWatchLater(playlist),
                                tooltip: 'Ver más tarde',
                              ),
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                        padding: EdgeInsets.all(8),
                        child: Text(
                          playlist['name'],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            shadows: [
                              Shadow(
                                blurRadius: 2,
                                color: Colors.black,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.info_outline,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InformationPage(
                                  singer: playlist['singer'] ?? '',
                                  information: playlist['information'] ?? '',
                                  imagen: playlist['imagen'],
                                ),
                              ),
                            );
                          },
                          tooltip: 'Información',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  final appColors = {
    'background': Color(0xFF0A0A0A),
    'accent': Color(0xFF00E5FF),
    'secondary': Color(0xFFFF0099),
    'surface': Color(0xFF1A1A1A),
    'text': Colors.white,
  };
}