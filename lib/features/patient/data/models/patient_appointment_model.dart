class PatientAppointmentModel {
  final int id;
  final int patientId;
  final int doctorId;
  final int? hospitalId;
  final String doctorName;
  final String date;
  final String time;
  final String status;
  final int? invoiceId;
  final String paymentStatus;
  final bool refundLogged;
  final String emailStatus;
  final String emailError;
  final bool canReview;
  final bool hasReview;
  final int? reviewId;

  const PatientAppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.hospitalId,
    required this.doctorName,
    required this.date,
    required this.time,
    required this.status,
    required this.invoiceId,
    required this.paymentStatus,
    required this.refundLogged,
    required this.emailStatus,
    required this.emailError,
    required this.canReview,
    required this.hasReview,
    required this.reviewId,
  });

  factory PatientAppointmentModel.fromJson(Map<String, dynamic> json) {
    return PatientAppointmentModel(
      id:
          _int(json['AppointmentID'] ?? json['appointment_id'] ?? json['id']) ??
          0,
      patientId: _int(json['PatientID'] ?? json['patient_id']) ?? 0,
      doctorId: _int(json['DoctorID'] ?? json['doctor_id']) ?? 0,
      hospitalId: _int(json['HospitalID'] ?? json['hospital_id']),
      doctorName: _text(json['DoctorName'] ?? json['doctor_name']),
      date: _dateText(json['Date'] ?? json['AppointmentDate'] ?? json['date']),
      time: _timeText(json['Time'] ?? json['AppointmentTime'] ?? json['time']),
      status: _text(json['Status'] ?? json['status']),
      invoiceId: _int(json['InvoiceID'] ?? json['invoice_id']),
      paymentStatus: _text(json['PaymentStatus'] ?? json['payment_status']),
      refundLogged: _bool(json['RefundLogged'] ?? json['refund_logged']),
      emailStatus: _text(json['email_status'] ?? json['EmailStatus']),
      emailError: _text(json['email_error'] ?? json['EmailError']),
      canReview: _bool(json['CanReview'] ?? json['can_review']),
      hasReview: _bool(json['HasReview'] ?? json['has_review']),
      reviewId: _int(json['ReviewID'] ?? json['review_id']),
    );
  }

  bool get isActive {
    final value = status.toLowerCase();
    return value == 'scheduled' || value == 'rescheduled';
  }

  bool get isCancelled => status.toLowerCase() == 'cancelled';

  String get displayDoctorName =>
      doctorName.isEmpty ? 'Doctor #$doctorId' : doctorName;
}

class BookAppointmentRequest {
  final int doctorId;
  final int? hospitalId;
  final String date;
  final String time;

  const BookAppointmentRequest({
    required this.doctorId,
    required this.hospitalId,
    required this.date,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    'doctor_id': doctorId,
    if (hospitalId != null) 'hospital_id': hospitalId,
    'date': date,
    'time': time,
    'payment_outcome': 'success',
  };
}

class AppointmentRescheduleRequest {
  final String newDate;
  final String newTime;

  const AppointmentRescheduleRequest({
    required this.newDate,
    required this.newTime,
  });

  Map<String, dynamic> toJson() => {'new_date': newDate, 'new_time': newTime};
}

class DoctorReviewRequest {
  final int rating;
  final String? comment;

  const DoctorReviewRequest({required this.rating, this.comment});

  Map<String, dynamic> toJson() => {
    'Rating': rating,
    if (comment?.trim().isNotEmpty == true) 'Comment': comment!.trim(),
  };
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase().trim();
  return text == 'true' || text == '1' || text == 'yes';
}

String _text(dynamic value) => value?.toString().trim() ?? '';

String _dateText(dynamic value) {
  final text = _text(value);
  if (text.length >= 10) return text.substring(0, 10);
  return text;
}

String _timeText(dynamic value) {
  final text = _text(value);
  if (text.length == 5) return '$text:00';
  return text;
}
