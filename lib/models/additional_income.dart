class AdditionalIncome {
  final String id;
  final String label;
  final double amount;

  AdditionalIncome({
    String? id,
    required this.label,
    required this.amount,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'amount': amount,
      };

  factory AdditionalIncome.fromMap(Map<String, dynamic> data) {
    return AdditionalIncome(
      id: data['id'] as String?,
      label: data['label'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
