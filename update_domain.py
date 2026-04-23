def replace_in_file(filepath, old, new):
    with open(filepath, 'r') as f:
        c = f.read()
    with open(filepath, 'w') as f:
        f.write(c.replace(old, new))

# 1. Update Domain Model
model_file = 'lib/domain/model/subscription_plans/subscription_transaction.dart'
replace_in_file(model_file, 
    "required this.amountUsd,\n    required this.createdAt,\n  });",
    "required this.amountUsd,\n    required this.createdAt,\n    this.status = 'active',\n  });")
replace_in_file(model_file,
    "final DateTime? createdAt;\n}",
    "final DateTime? createdAt;\n  final String status;\n}")

# 2. Update DTO
dto_file = 'lib/data/dto/subscription_plans/subscription_transaction_dto.dart'
replace_in_file(dto_file,
    "required this.amountUsd,\n    this.createdAt,\n  });",
    "required this.amountUsd,\n    this.createdAt,\n    this.status = 'active',\n  });")
replace_in_file(dto_file,
    "final DateTime? createdAt;\n",
    "final DateTime? createdAt;\n  final String status;\n")
replace_in_file(dto_file,
    "amountUsd: _asDouble(data['amount_usd'], fallback: 0),\n      createdAt: createdAt,\n    );",
    "amountUsd: _asDouble(data['amount_usd'], fallback: 0),\n      createdAt: createdAt,\n      status: (data['status'] as String?) ?? 'active',\n    );")
replace_in_file(dto_file,
    "amountUsd: amountUsd,\n    );",
    "amountUsd: amountUsd,\n      status: 'active',\n    );")
replace_in_file(dto_file,
    "'amount_usd': amountUsd,\n      'created_at': FieldValue.serverTimestamp(),\n    };",
    "'amount_usd': amountUsd,\n      'created_at': FieldValue.serverTimestamp(),\n      'status': status,\n    };")
replace_in_file(dto_file,
    "amountUsd: amountUsd,\n      createdAt: createdAt,\n    );",
    "amountUsd: amountUsd,\n      createdAt: createdAt,\n      status: status,\n    );")

