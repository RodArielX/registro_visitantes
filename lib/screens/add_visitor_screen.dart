import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddVisitorScreen extends StatefulWidget {
  @override
  _AddVisitorScreenState createState() => _AddVisitorScreenState();
}

class _AddVisitorScreenState extends State<AddVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _motivoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  File? _imagen;
  final picker = ImagePicker();
  final supabase = Supabase.instance.client;
  bool _isSaving = false;

  Future<void> _seleccionarImagen() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imagen = File(pickedFile.path);
      });
    }
  }

  Future<String?> _subirImagen(File imagen) async {
    try {
      final nombreArchivo = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'fotos/$nombreArchivo';
      final bytes = await imagen.readAsBytes();

      // Intentar subir
      final res = await supabase.storage
          .from('imagenes')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      // Ojo, si la subida falla, lanza excepción o retorna error

      // Obtener URL pública correctamente
      final urlResponse = supabase.storage.from('imagenes').getPublicUrl(path);

      // getPublicUrl retorna un objeto { data: { publicUrl: ... } } o una String, dependiendo versión
      // Si es objeto, extrae urlResponse.data.publicUrl
      // Si es String, úsalo directo

      // Para asegurar, imprime para debug:
      print('URL subida imagen: $urlResponse');

      // Si es String:
      return urlResponse;
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }

  Future<void> _guardarVisitante() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? urlFoto;
      if (_imagen != null) {
        urlFoto = await _subirImagen(_imagen!);
      }

      print('URL que se guardará en la BD: $urlFoto');

      final usuario = supabase.auth.currentUser;

      await supabase.from('visitantes').insert({
        'nombre': _nombreController.text,
        'motivo': _motivoController.text,
        'hora': _selectedDate.toIso8601String(),
        'foto_url': urlFoto,
        'user_id': usuario?.id,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Visitante registrado con éxito'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar visitante: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _seleccionarFechaHora() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (fecha == null) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (hora == null) return;

    setState(() {
      _selectedDate = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final fechaHoraTexto = DateFormat('yyyy-MM-dd HH:mm').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Nuevo Visitante'),
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre del visitante',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              SizedBox(height: 16),

              // Motivo
              TextFormField(
                controller: _motivoController,
                decoration: InputDecoration(
                  labelText: 'Motivo de la visita',
                  prefixIcon: Icon(Icons.info_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              SizedBox(height: 16),

              // Fecha y Hora
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Hora: $fechaHoraTexto',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Icon(
                  Icons.calendar_today,
                  color: Colors.blue.shade700,
                ),
                onTap: _seleccionarFechaHora,
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              SizedBox(height: 24),

              // Foto
              _imagen != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _imagen!,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                  : ElevatedButton.icon(
                      icon: Icon(Icons.camera_alt),
                      label: Text('Tomar foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _seleccionarImagen,
                    ),
              SizedBox(height: 24),

              // Botón Guardar
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _guardarVisitante,
                  icon: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.save),
                  label: Text(_isSaving ? 'Guardando...' : 'Guardar visitante'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
