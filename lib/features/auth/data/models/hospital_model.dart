class HospitalModel {
  final int id;
  final String name;
  final String? location;
  final String? contactNumber;

  const HospitalModel({
    required this.id,
    required this.name,
    this.location,
    this.contactNumber,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    final id = _parseInt(
      json['HospitalID'] ?? json['hospital_id'] ?? json['id'],
    );
    final name = _parseString(
      json['Name'] ?? json['HospitalName'] ?? json['name'],
    );

    if (id == null || name == null) {
      throw const FormatException('Invalid hospital data.');
    }

    return HospitalModel(
      id: id,
      name: name,
      location: _parseString(json['Location'] ?? json['location']),
      contactNumber: _parseString(
        json['ContactNumber'] ?? json['contact_number'],
      ),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _parseString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
