class VisitorModel {
  final String id;
  final String plateNumber;
  final String visitorName;
  final String contactNumber;
  final String purpose;
  final String destinationBuilding;
  final String passNumber;
  final String? idPresented;
  final DateTime timeIn;
  final DateTime? timeOut;

  VisitorModel({
    required this.id,
    required this.plateNumber,
    required this.visitorName,
    required this.contactNumber,
    required this.purpose,
    required this.destinationBuilding,
    required this.passNumber,
    this.idPresented,
    required this.timeIn,
    this.timeOut,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'plateNumber': plateNumber,
        'visitorName': visitorName,
        'contactNumber': contactNumber,
        'purpose': purpose,
        'destinationBuilding': destinationBuilding,
        'passNumber': passNumber,
        'idPresented': idPresented,
        'timeIn': timeIn.toIso8601String(),
        'timeOut': timeOut?.toIso8601String(),
      };

  factory VisitorModel.fromJson(Map<String, dynamic> json) {
    return VisitorModel(
      id: json['id'] as String,
      plateNumber: json['plateNumber'] as String,
      visitorName: json['visitorName'] as String,
      contactNumber: json['contactNumber'] as String,
      purpose: json['purpose'] as String,
      destinationBuilding: json['destinationBuilding'] as String,
      passNumber: json['passNumber'] as String,
      idPresented: json['idPresented'] as String?,
      timeIn: DateTime.parse(json['timeIn'] as String),
      timeOut: json['timeOut'] != null
          ? DateTime.parse(json['timeOut'] as String)
          : null,
    );
  }
}
