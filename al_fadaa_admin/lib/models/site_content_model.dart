// نماذج محتوى الموقع الإلكتروني للوحة الإدارة — مطابقة لوحدة site-content في الخادم

class SiteServiceItem {
  final String id;
  final String slug;
  final String titleAr;
  final String titleEn;
  final String? shortAr;
  final String? shortEn;
  final String? fullAr;
  final String? fullEn;
  final String? icon;
  final String? image;
  final List<String> features;
  final int order;
  final bool isActive;

  SiteServiceItem({
    required this.id,
    required this.slug,
    required this.titleAr,
    required this.titleEn,
    this.shortAr,
    this.shortEn,
    this.fullAr,
    this.fullEn,
    this.icon,
    this.image,
    this.features = const [],
    this.order = 0,
    this.isActive = true,
  });

  factory SiteServiceItem.fromJson(Map<String, dynamic> json) => SiteServiceItem(
        id: json['id'] ?? '',
        slug: json['slug'] ?? '',
        titleAr: json['titleAr'] ?? '',
        titleEn: json['titleEn'] ?? '',
        shortAr: json['shortAr'],
        shortEn: json['shortEn'],
        fullAr: json['fullAr'],
        fullEn: json['fullEn'],
        icon: json['icon'],
        image: json['image'],
        features: (json['features'] as List?)?.map((e) => e.toString()).toList() ?? [],
        order: (json['order'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] ?? true,
      );

  Map<String, dynamic> toPayload() => {
        'slug': slug,
        'titleAr': titleAr,
        'titleEn': titleEn,
        if (shortAr != null) 'shortAr': shortAr,
        if (shortEn != null) 'shortEn': shortEn,
        if (fullAr != null) 'fullAr': fullAr,
        if (fullEn != null) 'fullEn': fullEn,
        if (icon != null) 'icon': icon,
        if (image != null) 'image': image,
        'features': features,
        'order': order,
        'isActive': isActive,
      };
}

class SiteSectorItem {
  final String id;
  final String titleAr;
  final String titleEn;
  final String? descAr;
  final String? descEn;
  final String? icon;
  final List<String> services;
  final int order;
  final bool isActive;

  SiteSectorItem({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    this.descAr,
    this.descEn,
    this.icon,
    this.services = const [],
    this.order = 0,
    this.isActive = true,
  });

  factory SiteSectorItem.fromJson(Map<String, dynamic> json) => SiteSectorItem(
        id: json['id'] ?? '',
        titleAr: json['titleAr'] ?? '',
        titleEn: json['titleEn'] ?? '',
        descAr: json['descAr'],
        descEn: json['descEn'],
        icon: json['icon'],
        services: (json['services'] as List?)?.map((e) => e.toString()).toList() ?? [],
        order: (json['order'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] ?? true,
      );

  Map<String, dynamic> toPayload() => {
        'titleAr': titleAr,
        'titleEn': titleEn,
        if (descAr != null) 'descAr': descAr,
        if (descEn != null) 'descEn': descEn,
        if (icon != null) 'icon': icon,
        'services': services,
        'order': order,
        'isActive': isActive,
      };
}

class SiteProjectItem {
  final String id;
  final String titleAr;
  final String titleEn;
  final String? tagAr;
  final String? tagEn;
  final String? scopeAr;
  final String? scopeEn;
  final List<String> metrics;
  final String? image;
  final int order;
  final bool isActive;

  SiteProjectItem({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    this.tagAr,
    this.tagEn,
    this.scopeAr,
    this.scopeEn,
    this.metrics = const [],
    this.image,
    this.order = 0,
    this.isActive = true,
  });

  factory SiteProjectItem.fromJson(Map<String, dynamic> json) => SiteProjectItem(
        id: json['id'] ?? '',
        titleAr: json['titleAr'] ?? '',
        titleEn: json['titleEn'] ?? '',
        tagAr: json['tagAr'],
        tagEn: json['tagEn'],
        scopeAr: json['scopeAr'],
        scopeEn: json['scopeEn'],
        metrics: (json['metrics'] as List?)?.map((e) => e.toString()).toList() ?? [],
        image: json['image'],
        order: (json['order'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] ?? true,
      );

  Map<String, dynamic> toPayload() => {
        'titleAr': titleAr,
        'titleEn': titleEn,
        if (tagAr != null) 'tagAr': tagAr,
        if (tagEn != null) 'tagEn': tagEn,
        if (scopeAr != null) 'scopeAr': scopeAr,
        if (scopeEn != null) 'scopeEn': scopeEn,
        'metrics': metrics,
        if (image != null) 'image': image,
        'order': order,
        'isActive': isActive,
      };
}

class SiteFaqItem {
  final String id;
  final String questionAr;
  final String questionEn;
  final String answerAr;
  final String answerEn;
  final int order;
  final bool isActive;

  SiteFaqItem({
    required this.id,
    required this.questionAr,
    required this.questionEn,
    required this.answerAr,
    required this.answerEn,
    this.order = 0,
    this.isActive = true,
  });

  factory SiteFaqItem.fromJson(Map<String, dynamic> json) => SiteFaqItem(
        id: json['id'] ?? '',
        questionAr: json['questionAr'] ?? '',
        questionEn: json['questionEn'] ?? '',
        answerAr: json['answerAr'] ?? '',
        answerEn: json['answerEn'] ?? '',
        order: (json['order'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] ?? true,
      );

  Map<String, dynamic> toPayload() => {
        'questionAr': questionAr,
        'questionEn': questionEn,
        'answerAr': answerAr,
        'answerEn': answerEn,
        'order': order,
        'isActive': isActive,
      };
}

class SiteSettingItem {
  final String id;
  final String key;
  final dynamic value;
  final String? description;
  final DateTime updatedAt;

  SiteSettingItem({
    required this.id,
    required this.key,
    required this.value,
    this.description,
    required this.updatedAt,
  });

  factory SiteSettingItem.fromJson(Map<String, dynamic> json) => SiteSettingItem(
        id: json['id'] ?? '',
        key: json['key'] ?? '',
        value: json['value'],
        description: json['description'],
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );
}
