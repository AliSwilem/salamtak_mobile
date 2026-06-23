class PatientHospitalModel {
  final int id;
  final String name;
  final String location;

  const PatientHospitalModel({
    required this.id,
    required this.name,
    required this.location,
  });

  factory PatientHospitalModel.fromJson(Map<String, dynamic> json) {
    return PatientHospitalModel(
      id: _int(json['HospitalID'] ?? json['hospital_id']) ?? 0,
      name: _text(json['Name'] ?? json['name']),
      location: _text(json['Location'] ?? json['location']),
    );
  }
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String _text(dynamic value) => value?.toString().trim() ?? '';
