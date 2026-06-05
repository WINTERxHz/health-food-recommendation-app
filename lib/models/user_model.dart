class UserModel {
  final String firstName;
  final String lastName;
  final String dietType;
  final String goal;
  final double weight;
  final double height;
  final double bmi;
  final String? photoUrl;

  // 1. เพิ่ม 2 บรรทัดนี้
  final String gender;
  final DateTime? birthDate;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.dietType,
    required this.goal,
    required this.weight,
    required this.height,
    required this.bmi,
    this.photoUrl,
    required this.gender, // เพิ่ม
    this.birthDate, // เพิ่ม
  });

  String get fullName => "$firstName $lastName".trim();

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      firstName: map['firstName'] ?? "",
      lastName: map['lastName'] ?? "",
      dietType: map['dietType'] ?? "Balanced",
      goal: map['goal'] ?? "Maintain",
      weight: (map['weight'] ?? 0).toDouble(),
      height: (map['height'] ?? 0).toDouble(),
      bmi: (map['bmi'] ?? 0).toDouble(),
      photoUrl: map['photoUrl'],
      // 2. รับค่าจาก Map
      gender: map['gender'] ?? "Male",
      birthDate:
          map['birthDate'] != null ? DateTime.tryParse(map['birthDate']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "dietType": dietType,
      "goal": goal,
      "weight": weight,
      "height": height,
      "bmi": bmi,
      "photoUrl": photoUrl,
      // 3. แปลงกลับเป็น Map
      "gender": gender,
      "birthDate": birthDate?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? dietType,
    String? goal,
    double? weight,
    double? height,
    double? bmi,
    String? photoUrl,
    String? gender,
    DateTime? birthDate,
  }) {
    return UserModel(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dietType: dietType ?? this.dietType,
      goal: goal ?? this.goal,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bmi: bmi ?? this.bmi,
      photoUrl: photoUrl ?? this.photoUrl,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
    );
  }
}
