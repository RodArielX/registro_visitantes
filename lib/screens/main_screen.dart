import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_visitor_screen.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final supabase = Supabase.instance.client;
  late RealtimeChannel canal;

  @override
  void initState() {
    super.initState();

    canal = supabase.channel('public:visitantes')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(event: '*', schema: 'public', table: 'visitantes'),
        (payload, [ref]) {
          setState(() {});
        },
      )
      ..subscribe();
  }

  @override
  void dispose() {
    supabase.removeChannel(canal); // Limpia canal al salir
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> obtenerVisitantes() async {
    final response = await supabase
        .from('visitantes')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visitantes registrados'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await supabase.auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: obtenerVisitantes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: Colors.blue.shade900),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No hay visitantes registrados',
                  style: TextStyle(fontSize: 18, color: Colors.blueGrey),
                ),
              );
            }

            final visitantes = snapshot.data!;
            return ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              itemCount: visitantes.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.blueGrey.shade100),
              itemBuilder: (context, index) {
                final v = visitantes[index];
                final fechaHora = DateTime.tryParse(v['hora'] ?? '')?.toLocal();

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: (v['foto_url'] != null && v['foto_url'] != '')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.network(
                              v['foto_url'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.blue.shade200,
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          )
                        : CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.blue.shade200,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                    title: Text(
                      v['nombre'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      '${v['motivo']} — ${fechaHora != null ? '${fechaHora.day}/${fechaHora.month}/${fechaHora.year} ${fechaHora.hour.toString().padLeft(2, '0')}:${fechaHora.minute.toString().padLeft(2, '0')}' : v['hora']}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Agregar nuevo visitante',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddVisitorScreen()),
          ).then((_) => setState(() {}));
        },
        backgroundColor: Colors.blue.shade900,
        child: Icon(Icons.add),
      ),
    );
  }
}
