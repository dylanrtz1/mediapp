import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo para una sola cuenta bancaria, necesario para el doctor
class BankAccount {
  final String bankName;
  final String accountType;
  final String accountNumber;
  final String beneficiaryName;
  final String beneficiaryId;

  BankAccount({
    this.bankName = '',
    this.accountType = '',
    this.accountNumber = '',
    this.beneficiaryName = '',
    this.beneficiaryId = '',
  });

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    return BankAccount(
      bankName: map['bankName'] ?? '',
      accountType: map['accountType'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      beneficiaryName: map['beneficiaryName'] ?? '',
      beneficiaryId: map['beneficiaryId'] ?? '',
    );
  }
}

class Doctor {
  final String id;
  final String authUid;
  final String name;
  final String city;
  final String specialty;
  final String subSpecialty;
  final String mspRegistrationNumber;
  final String senescytRegistrationNumber;
  final int yearsOfExperience;
  final int casesPerformed;
  final double priceRegular;
  final double priceWithApp;
  final String imagePath;
  final String videoUrl;
  final double rating;
  final int reviewCount;

  // --- CAMPOS NUEVOS Y ACTUALIZADOS ---
  final String about;
  final List<Map<String, dynamic>> services;
  final List<dynamic> beforeAndAfterImageUrls;
  final String paymentLink;
  final List<BankAccount> bankAccounts;
  final List<Map<String, dynamic>> courses;

  Doctor({
    required this.id,
    required this.authUid,
    required this.name,
    required this.city,
    required this.specialty,
    required this.subSpecialty,
    required this.mspRegistrationNumber,
    required this.senescytRegistrationNumber,
    required this.yearsOfExperience,
    required this.casesPerformed,
    required this.priceRegular,
    required this.priceWithApp,
    required this.imagePath,
    required this.videoUrl,
    required this.rating,
    required this.reviewCount,
    required this.about,
    required this.services,
    required this.beforeAndAfterImageUrls,
    required this.paymentLink,
    required this.bankAccounts,
    required this.courses,
  });

  factory Doctor.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    var accountsData = data['bankAccounts'] as List<dynamic>? ?? [];
    List<BankAccount> accounts = accountsData.map((acc) => BankAccount.fromMap(acc as Map<String, dynamic>)).toList();

    return Doctor(
      id: doc.id,
      authUid: data['authUid'] ?? '',
      name: data['name'] ?? 'Sin Nombre',
      city: data['city'] ?? 'Sin Ciudad',
      specialty: data['specialty'] ?? 'Sin Especialidad',
      subSpecialty: data['subSpecialty'] ?? '',
      mspRegistrationNumber: data['mspRegistrationNumber'] ?? 'N/A',
      senescytRegistrationNumber: data['senescytRegistrationNumber'] ?? 'N/A',
      yearsOfExperience: data['yearsOfExperience'] ?? 0,
      casesPerformed: data['casesPerformed'] ?? 0,
      priceRegular: (data['priceRegular'] ?? 0.0).toDouble(),
      priceWithApp: (data['priceWithApp'] ?? 0.0).toDouble(),
      imagePath: data['imagePath'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,

      // --- LECTURA DE LOS NUEVOS CAMPOS DESDE FIREBASE ---
      about: data['about'] ?? '',
      services: List<Map<String, dynamic>>.from(data['services'] ?? []),
      beforeAndAfterImageUrls: data['beforeAndAfterImageUrls'] ?? [],
      paymentLink: data['paymentLink'] ?? '',
      bankAccounts: accounts,
      courses: List<Map<String, dynamic>>.from(data['courses'] ?? []),
    );
  }
}