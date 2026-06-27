import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salamtak_mobile/features/auth/data/models/doctor_register_request.dart';
import 'package:salamtak_mobile/features/auth/data/models/patient_register_request.dart';
import 'package:salamtak_mobile/features/auth/data/models/register_response.dart';
import 'package:salamtak_mobile/features/auth/presentation/register_role_screen.dart';

void main() {
  test(
    'patient registration maps backend field names and omits empty optionals',
    () {
      const request = PatientRegisterRequest(
        username: 'patient',
        email: 'patient@example.com',
        password: 'secret12',
        fullName: 'Test Patient',
        gender: 'female',
        dateOfBirth: '1995-04-12',
        contactNumber: '01000000000',
        address: ' ',
      );

      expect(request.toJson(), {
        'username': 'patient',
        'email': 'patient@example.com',
        'password': 'secret12',
        'full_name': 'Test Patient',
        'gender': 'female',
        'date_of_birth': '1995-04-12',
        'contact_number': '01000000000',
      });
    },
  );

  test('doctor registration sends backend HospitalID casing', () {
    const request = DoctorRegisterRequest(
      username: 'doctor',
      email: 'doctor@example.com',
      password: 'secret12',
      fullName: 'Test Doctor',
      specialization: 'Cardiology',
      phone: '01000000001',
      medicalLicenseNumber: 'LIC-123',
      yearsOfExperience: 7,
      hospitalId: 3,
    );

    expect(request.toJson()['HospitalID'], 3);
    expect(request.toJson()['medical_license_number'], 'LIC-123');
  });

  test('registration response parses token and PascalCase identifiers', () {
    final response = RegisterResponse.fromJson({
      'access_token': 'token',
      'token_type': 'bearer',
      'role': 'doctor',
      'UserID': 8,
      'DoctorID': 5,
    });

    expect(response.hasToken, isTrue);
    expect(response.role, 'doctor');
    expect(response.userId, 8);
    expect(response.doctorId, 5);
  });

  testWidgets('role selection exposes patient and doctor only', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterRoleScreen()));

    expect(find.text('Register as Patient'), findsOneWidget);
    expect(find.text('Register as Doctor'), findsOneWidget);
    expect(find.textContaining('Admin'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
