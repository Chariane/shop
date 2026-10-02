class DeliveryAddress {
  final String fullName;
  final String phone;
  final String street;
  final String city;
  final String country;

  const DeliveryAddress({
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
    required this.country,
  });

  String get location => '$city, $country';
}

class DeliveryOption {
  final String id;
  final String name;
  final String description;
  final String estimatedLabel;
  final double fee;

  const DeliveryOption({
    required this.id,
    required this.name,
    required this.description,
    required this.estimatedLabel,
    required this.fee,
  });
}
