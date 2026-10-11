import 'package:dio/dio.dart';

class MockApiInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Never mock auth endpoints - let real server responses and errors pass directly to the app!
    if (err.requestOptions.path.contains('/auth/')) {
      return handler.next(err);
    }

    // If the server returned an explicit client error (400, 401, 422), do not mock it; let the real message through!
    final statusCode = err.response?.statusCode;
    if (statusCode == 400 || statusCode == 401 || statusCode == 422) {
      return handler.next(err);
    }

    final path = err.requestOptions.path;
    final method = err.requestOptions.method;

    final mockResponse =
        _getMockResponse(path, method, options: err.requestOptions);
    if (mockResponse != null) {
      final response = Response(
        requestOptions: err.requestOptions,
        data: mockResponse,
        statusCode: 200,
      );
      return handler.resolve(response);
    }

    return handler.next(err);
  }

  dynamic _getMockResponse(String path, String method,
      {RequestOptions? options}) {
    // 1. AUTH
    if (path.contains('/auth/register')) {
      return {
        'message': 'تم تسجيل الحساب بنجاح',
        'status': true,
        'user': {
          'id': 102,
          'first_name': 'أسامة',
          'last_name': 'صبري',
          'email': 'osama@example.com',
          'phone': '+966555123456',
          'display_name': 'أسامة صبري',
          'avatar_url':
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
        },
      };
    }
    if (path.contains('/auth/login')) {
      String email = 'user@modeefe.sa';
      String name = 'مسافر مُضيف';
      if (options?.data is Map) {
        final reqData = options!.data as Map;
        if (reqData['email'] != null &&
            reqData['email'].toString().isNotEmpty) {
          email = reqData['email'].toString();
          final userPart = email.split('@').first;
          name = userPart[0].toUpperCase() +
              (userPart.length > 1 ? userPart.substring(1) : '');
        }
      }
      return {
        'access_token': 'modeefe_secure_jwt_token_sample',
        'user': {
          'id': 101,
          'first_name': name,
          'last_name': '',
          'email': email,
          'phone': '+966555123456',
          'display_name': name,
          'avatar_url':
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
        },
        'status': 1
      };
    }
    if (path.contains('/auth/me')) {
      return {
        'status': 1,
        'data': {
          'id': 101,
          'first_name': 'أسامة',
          'last_name': 'صبري',
          'email': 'osama@example.com',
          'phone': '+966555123456',
          'avatar_url':
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
          'role_id': 3,
        }
      };
    }
    if (path.contains('/auth/change-password')) {
      return {'message': 'تم تحديث كلمة المرور بنجاح', 'status': 1};
    }
    if (path.contains('/auth/logout')) {
      return {'message': 'تم تسجيل الخروج بنجاح', 'status': true};
    }
    if (path.contains('/forgot-password') || path.contains('/reset-password')) {
      return {
        'message': 'تم إرسال رابط الاستعادة إلى بريدك الإلكتروني',
        'status': 1
      };
    }

    // 2. DISCOVERY & CONTENT
    if (path.contains('/services')) {
      return {
        'status': 1,
        'data': [
          {
            'id': 1,
            'name': 'تجارب سياحية',
            'slug': 'tours',
            'icon': 'icofont-island-alt'
          },
          {
            'id': 2,
            'name': 'المتاحف والتراث',
            'slug': 'museums',
            'icon': 'icofont-bank-alt'
          },
          {
            'id': 3,
            'name': 'الفعاليات والمواسم',
            'slug': 'events',
            'icon': 'icofont-calendar'
          },
          {
            'id': 4,
            'name': 'مرشدون سياحيون',
            'slug': 'guides',
            'icon': 'icofont-user'
          },
          {
            'id': 5,
            'name': 'تأجير سيارات',
            'slug': 'cars',
            'icon': 'icofont-car-alt-4'
          },
          {
            'id': 6,
            'name': 'بازار مُضيف',
            'slug': 'shop',
            'icon': 'icofont-shopping-cart'
          }
        ]
      };
    }
    if (path.contains('/locations')) {
      return {
        'status': 1,
        'data': [
          {
            'id': 1,
            'name': 'العُلا - عروس الجبال',
            'slug': 'alula',
            'image_url':
                'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80',
            'banner_image':
                'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=1200&q=80'
          },
          {
            'id': 2,
            'name': 'الدرعية التاريخية',
            'slug': 'diriyah',
            'image_url':
                'https://images.unsplash.com/photo-1586724237569-f3d0c1dee8c6?w=800&q=80',
            'banner_image':
                'https://images.unsplash.com/photo-1586724237569-f3d0c1dee8c6?w=1200&q=80'
          },
          {
            'id': 3,
            'name': 'البلد التاريخية - جدة',
            'slug': 'al-balad',
            'image_url':
                'https://images.unsplash.com/photo-1586724237569-f3d0c1dee8c6?w=800&q=80',
            'banner_image':
                'https://images.unsplash.com/photo-1578895101407-28d8442e61df?w=1200&q=80'
          },
          {
            'id': 4,
            'name': 'رجال ألمع - عسير',
            'slug': 'rijal-almaa',
            'image_url':
                'https://images.unsplash.com/photo-1548013146-72479768bada?w=800&q=80',
            'banner_image':
                'https://images.unsplash.com/photo-1548013146-72479768bada?w=1200&q=80'
          }
        ]
      };
    }
    if (path.contains('/news')) {
      return {
        'status': 1,
        'data': [
          {
            'id': 1,
            'title': 'انطلاق فعاليات شتاء طنطورة في العلا ببرامج تراثية مميزة',
            'content':
                'تجارب ثقافية وفنية حية تجمع بين عراقة الماضي وأصالة الضيافة السعودية.',
            'image_url':
                'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80',
            'created_at': '2026-09-01'
          },
          {
            'id': 2,
            'title':
                'افتتاح قصر المربع التاريخي بعد أعمال الترميم الكبرى بالرياض',
            'content':
                'وجهة وطنية تسرد ملامح تأسيس الدولة السعودية الحديثة وعبق التاريخ.',
            'image_url':
                'https://images.unsplash.com/photo-1586724237569-f3d0c1dee8c6?w=800&q=80',
            'created_at': '2026-08-28'
          }
        ]
      };
    }
    if (path.contains('/configs/countries') || path.contains('/configs')) {
      return {
        'status': 1,
        'data': [
          {'id': 1, 'name': 'المملكة العربية السعودية', 'code': 'SA'},
          {'id': 2, 'name': 'الإمارات العربية المتحدة', 'code': 'AE'},
          {'id': 3, 'name': 'الكويت', 'code': 'KW'},
          {'id': 4, 'name': 'قطر', 'code': 'QA'},
          {'id': 5, 'name': 'البحرين', 'code': 'BH'},
          {'id': 6, 'name': 'عُمان', 'code': 'OM'}
        ]
      };
    }

    // 3. TOURS
    if (path.contains('/tour/search')) {
      return {
        'status': 1,
        'total': 4,
        'total_pages': 1,
        'data': [
          {
            'id': 16,
            'object_model': 'tour',
            'title': 'جولة الحِجر الأثرية واستكشاف مدائن صالح',
            'price': 450,
            'sale_price': 380,
            'discount_percent': '15%',
            'image_url':
                'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80',
            'content':
                'اكتشف أول موقع سعودي مدرج في قائمة اليونسكو للتراث العالمي بصحبة مرشد سياحي مرخص وتجربة ضيافة نجدية وحجازية أصيلة.',
            'location': {'id': 1, 'name': 'العُلا'},
            'category': {'id': 2, 'name': 'تراث وآثار'},
            'is_featured': 1,
            'is_wishlist': 0,
            'duration': '4 ساعات',
            'review_score': {'score_total': 4.9, 'total_review': 34}
          },
          {
            'id': 17,
            'object_model': 'tour',
            'title': 'جولة الطريف المسائية وعبق تأسيس الدولة',
            'price': 250,
            'sale_price': null,
            'image_url':
                'https://images.unsplash.com/photo-1586724237569-f3d0c1dee8c6?w=800&q=80',
            'content':
                'استمتع بجولة مسائية مذهلة بين مباني الطين النجدية الأصيلة في حي الطريف التاريخي مع عشاء نجدي فاخر.',
            'location': {'id': 2, 'name': 'الدرعية - الرياض'},
            'category': {'id': 1, 'name': 'تراث وثقافة'},
            'is_featured': 1,
            'is_wishlist': 1,
            'duration': '3 ساعات',
            'review_score': {'score_total': 4.8, 'total_review': 52}
          },
          {
            'id': 18,
            'object_model': 'tour',
            'title': 'رحلة حافة العالم وسفاري صحراء نجد',
            'price': 500,
            'sale_price': 420,
            'image_url':
                'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?w=800&q=80',
            'content':
                'مغامرة دفع رباعي إلى مطل حافة العالم الشاهق مع جلسة سمر وشاي كرك وتأمل النجوم بالصحراء.',
            'location': {'id': 2, 'name': 'الرياض'},
            'category': {'id': 3, 'name': 'مغامرات وطبيعة'},
            'is_featured': 1,
            'is_wishlist': 0,
            'duration': '6 ساعات',
            'review_score': {'score_total': 5.0, 'total_review': 28}
          },
          {
            'id': 19,
            'object_model': 'tour',
            'title': 'مسار البلد التاريخية ورواشين جدة القديمة',
            'price': 200,
            'sale_price': null,
            'image_url':
                'https://images.unsplash.com/photo-1586724237569-f3d0c1dee8c6?w=800&q=80',
            'content':
                'جولة مشي شيقة بين الأزقة العتيقة وبيت نصيف وسوق الندى وتذوق أشهر المأكولات الحجازية الشعبية.',
            'location': {'id': 3, 'name': 'جدة'},
            'category': {'id': 1, 'name': 'ثقافة وتراث'},
            'is_featured': 0,
            'is_wishlist': 0,
            'duration': '2.5 ساعة',
            'review_score': {'score_total': 4.7, 'total_review': 19}
          }
        ]
      };
    }
    if (path.contains('/tour/filters')) {
      return {
        'status': 1,
        'data': [
          {
            'title': 'نطاق السعر',
            'field': 'price_range',
            'position': '1',
            'min_price': 100,
            'max_price': 1500
          },
          {
            'title': 'تقييم التجربة',
            'field': 'review_score',
            'position': '2',
            'min': '1',
            'max': '5'
          }
        ]
      };
    }
    if (path.contains('/tour/detail')) {
      return {
        'status': 1,
        'data': {
          'id': 16,
          'title': 'جولة الحِجر الأثرية واستكشاف مدائن صالح',
          'price': 450,
          'sale_price': 380,
          'duration': '4 ساعات',
          'content':
              'انضم إلينا في رحلة ساحرة إلى قلب العُلا التاريخية واستكشف مقابر النبطيين المنحوتة في الصخور الرملية الذهبية مع مرشد متخصص يحكي أسرار الحضارات القديمة.',
          'image_url':
              'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=800&q=80',
          'banner_image':
              'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=1200&q=80',
          'review_score': {'score_total': 4.9, 'total_review': 34},
          'category': {'id': 2, 'name': 'تراث وآثار'},
          'location': {'id': 1, 'name': 'العُلا'},
          'min_people': 1,
          'max_people': 12,
          'include': [
            'مرشد سياحي مرخص',
            'وسيلة نقل مكيفة',
            'ضيافة قهوة وتمر سعودي',
            'رسوم دخول المعالم'
          ],
          'exclude': ['المصاريف الشخصية', 'التأمين الاختياري'],
          'faqs': [
            {
              'title': 'ما هي الملابس المناسبة للجولة؟',
              'content': 'ملابس مريحة وأحذية مناسبة للمشي في الطبيعة والصخور.'
            },
            {
              'title': 'هل تناسب الجولة العائلات والأطفال؟',
              'content': 'نعم، الجولة مهيأة لجميع أفراد العائلة.'
            }
          ]
        }
      };
    }

    // 4. GUIDES
    if (path.contains('/guide/search')) {
      return {
        'total': 4,
        'total_pages': 1,
        'status': 1,
        'data': [
          {
            'id': 72,
            'name': 'عبدالله القادري',
            'avatar_url':
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&q=80',
            'city': 'العُلا',
            'bio':
                'مرشد سياحي معتمد متخصص في تاريخ وآثار شبه الجزيرة العربية ومدائن صالح.',
            'languages': ['العربية', 'الإنجليزية'],
            'price': '150.00',
            'review_score': 4.9,
            'tours_count': 64
          },
          {
            'id': 73,
            'name': 'سارة الغامدي',
            'avatar_url':
                'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=800&q=80',
            'city': 'الرياض',
            'bio':
                'باحثة تراثية ومرشدة معتمدة للجولات التاريخية وقصور الدرعية.',
            'languages': ['العربية', 'الإنجليزية', 'الفرنسية'],
            'price': '180.00',
            'review_score': 5.0,
            'tours_count': 92
          },
          {
            'id': 74,
            'name': 'محمد العتيبي',
            'avatar_url':
                'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&q=80',
            'city': 'جدة',
            'bio':
                'خبير مسارات تاريخية وفنون معمارية في جدة التاريخية ومكة المكرمة.',
            'languages': ['العربية', 'الإنجليزية'],
            'price': '140.00',
            'review_score': 4.8,
            'tours_count': 45
          },
          {
            'id': 75,
            'name': 'نورة الزهراني',
            'avatar_url':
                'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=800&q=80',
            'city': 'عسير - أبها',
            'bio':
                'مرشدة طبيعة واستكشاف في جبال السودة وقرية رجال ألمع التراثية.',
            'languages': ['العربية', 'الإنجليزية'],
            'price': '160.00',
            'review_score': 4.9,
            'tours_count': 58
          }
        ]
      };
    }
    if (path.contains('/guide/detail')) {
      return {
        'status': 1,
        'data': {
          'id': 72,
          'name': 'عبدالله القادري',
          'avatar_url':
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&q=80',
          'city': 'العُلا',
          'bio':
              'مرشد سياحي معتمد لدى وزارة السياحة السعودية، بخبرة تفوق 8 سنوات في توثيق وتقديم جولات الحِجر والعلا القديمة وجبل الفيل.',
          'languages': ['العربية', 'الإنجليزية'],
          'price': '150.00',
          'review_score': 4.9,
          'tours_count': 64
        }
      };
    }

    // 5. CARS
    if (path.contains('/car/search')) {
      return {
        'status': 1,
        'total': 4,
        'total_pages': 1,
        'data': [
          {
            'id': 10,
            'title': 'تويوتا لاندكروزر VXR 2026',
            'category': {'name': 'دفع رباعي فاخر'},
            'price': 850,
            'sale_price': 750,
            'passenger': 7,
            'gear': 'أوتوماتيك',
            'image_url':
                'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=800&q=80'
          },
          {
            'id': 11,
            'title': 'لكزس LX600 VIP',
            'category': {'name': 'فخامة ملكية'},
            'price': 1400,
            'sale_price': null,
            'passenger': 5,
            'gear': 'أوتوماتيك',
            'image_url':
                'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&q=80'
          },
          {
            'id': 12,
            'title': 'مرسيدس G-Class G63',
            'category': {'name': 'سوبر فارهة'},
            'price': 2200,
            'sale_price': 1950,
            'passenger': 5,
            'gear': 'أوتوماتيك',
            'image_url':
                'https://images.unsplash.com/photo-1520031441872-265e4ff70366?w=800&q=80'
          },
          {
            'id': 13,
            'title': 'هيونداي ستاريا VIP سياحية',
            'category': {'name': 'عائلية سياحية'},
            'price': 600,
            'sale_price': 520,
            'passenger': 9,
            'gear': 'أوتوماتيك',
            'image_url':
                'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=800&q=80'
          }
        ]
      };
    }
    if (path.contains('/car/detail')) {
      return {
        'status': 1,
        'data': {
          'id': 10,
          'title': 'تويوتا لاندكروزر VXR 2026',
          'category': {'name': 'دفع رباعي فاخر'},
          'price': 850,
          'sale_price': 750,
          'passenger': 7,
          'gear': 'أوتوماتيك',
          'image_url':
              'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=800&q=80',
          'content':
              'سيارة دفع رباعي فاخرة ومجهزة بالكامل للرحلات الصحراوية والمسارات الجبلية في المملكة مع سائق خاص أو قيادة ذاتية.'
        }
      };
    }

    // 6. EVENTS
    if (path.contains('/event/search')) {
      return {
        'status': 1,
        'total': 4,
        'total_pages': 1,
        'data': [
          {
            'id': 12,
            'title': 'مهرجان سماء العلا للمناطيد والنجوم',
            'price': 350,
            'start_date': '15 أكتوبر 2026',
            'location': {'name': 'العُلا'},
            'image_url':
                'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80'
          },
          {
            'id': 13,
            'title': 'أمسيات الطريف الشعرية والتراثية',
            'price': 120,
            'start_date': 'كل جمعة وسبت',
            'location': {'name': 'الدرعية - الرياض'},
            'image_url':
                'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&q=80'
          },
          {
            'id': 14,
            'title': 'مهرجان الورد الطائفي الثقافي',
            'price': 80,
            'start_date': 'موسم الربيع',
            'location': {'name': 'الطائف'},
            'image_url':
                'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&q=80'
          }
        ]
      };
    }
    if (path.contains('/event/detail')) {
      return {
        'status': 1,
        'data': {
          'id': 12,
          'title': 'مهرجان سماء العلا للمناطيد والنجوم',
          'price': 350,
          'start_date': '15 أكتوبر 2026',
          'location': {'name': 'العُلا'},
          'image_url':
              'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
          'content':
              'تجربة استثنائية للتحليق بالمناطيد الملونة فوق تشكيلات الصخور الرملية الخلابة في العلا مع فعاليات ترفيهية مسائية وموسيقى حية.'
        }
      };
    }

    // 7. MUSEUMS
    if (path.contains('/museum/search')) {
      return {
        'status': 1,
        'total': 3,
        'total_pages': 1,
        'data': [
          {
            'id': 31,
            'title': 'المتحف الوطني السعودي بالرياض',
            'price': 50,
            'location': 'الرياض',
            'open_hours': '9:00 ص - 9:00 م',
            'image_url':
                'https://images.unsplash.com/photo-1566127444979-b3d2b654e3d7?w=800&q=80'
          },
          {
            'id': 32,
            'title': 'متحف قصر خزام التاريخي',
            'price': 35,
            'location': 'جدة',
            'open_hours': '10:00 ص - 8:00 م',
            'image_url':
                'https://images.unsplash.com/photo-1582555172866-f73bb12a2ab3?w=800&q=80'
          },
          {
            'id': 33,
            'title': 'متحف رجال ألمع للتراث العسيري',
            'price': 40,
            'location': 'عسير',
            'open_hours': '8:00 ص - 7:00 م',
            'image_url':
                'https://images.unsplash.com/photo-1548013146-72479768bada?w=800&q=80'
          }
        ]
      };
    }
    if (path.contains('/museum/detail')) {
      return {
        'status': 1,
        'data': {
          'id': 31,
          'title': 'المتحف الوطني السعودي بالرياض',
          'price': 50,
          'location': 'الرياض',
          'open_hours': '9:00 ص - 9:00 م',
          'image_url':
              'https://images.unsplash.com/photo-1566127444979-b3d2b654e3d7?w=800&q=80',
          'content':
              'رحلة عبر 8 قاعات تفاعلية تسرد قصة الإنسان والكون والممالك العربية القديمة وتأسيس الدولة السعودية في صرح معماري مبهر.'
        }
      };
    }

    // 8. BAZAAR & PRODUCTS
    if (path.contains('/product/search')) {
      return {
        'status': 1,
        'total': 4,
        'total_pages': 1,
        'data': [
          {
            'id': 22,
            'title': 'تمر عجوة المدينة الملكي الفاخر',
            'price': 140,
            'sale_price': 115,
            'category': {'name': 'تمور وأغذية تراثية'},
            'image_url':
                'https://images.unsplash.com/photo-1596797882870-8c33deeac224?w=800&q=80',
            'is_featured': true
          },
          {
            'id': 23,
            'title': 'دهن عود وورد طائفي ملكي معتق',
            'price': 350,
            'sale_price': 290,
            'category': {'name': 'عطور وبخور'},
            'image_url':
                'https://images.unsplash.com/photo-1594035910387-fea47794261f?w=800&q=80',
            'is_featured': true
          },
          {
            'id': 24,
            'title': 'دلة قهوة سعودية مذهبة نقش نجدي',
            'price': 220,
            'sale_price': null,
            'category': {'name': 'مقتنيات وتحف'},
            'image_url':
                'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=800&q=80',
            'is_featured': false
          },
          {
            'id': 25,
            'title': 'سبحة بكلايت ملكية خراط يدوي فاخر',
            'price': 180,
            'sale_price': 150,
            'category': {'name': 'سبح ومجوهرات'},
            'image_url':
                'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=800&q=80',
            'is_featured': true
          }
        ]
      };
    }
    if (path.contains('/product/detail')) {
      return {
        'status': 1,
        'data': {
          'id': 22,
          'title': 'تمر عجوة المدينة الملكي الفاخر',
          'price': 140,
          'sale_price': 115,
          'category': {'name': 'تمور وأغذية تراثية'},
          'image_url':
              'https://images.unsplash.com/photo-1596797882870-8c33deeac224?w=800&q=80',
          'content':
              'تمر عجوة نخب أول من مزارع المدينة المنورة المباركة، مختارة حبة بحبة ومغلفة بعناية فائقة في صندوق هدايا تراثي فاخر يحمل هوية مُضيف.'
        }
      };
    }

    // 9. CART & CHECKOUT
    if (path.contains('/gateways')) {
      return {
        'status': 1,
        'moyasar': {
          'name': 'ميسر (بطاقة مدى / فيزا / أبل باي)',
          'is_offline': false,
          'supports_cart': true
        },
        'applepay': {
          'name': 'Apple Pay',
          'is_offline': false,
          'supports_cart': true
        },
        'offline': {
          'name': 'الدفع عند الوصول',
          'is_offline': true,
          'supports_cart': true
        }
      };
    }
    if (path.contains('/cart/checkout')) {
      return {
        'status': 'processing',
        'message': 'تم تأكيد حجزك وطلبك بنجاح!',
        'order_code':
            'MDF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'subtotal': 0,
        'discount': 0,
        'total': 0
      };
    }
    if (path.contains('/booking/addToCart')) {
      return {
        'status': 1,
        'booking_code':
            'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'message': 'تمت الإضافة إلى السلة بنجاح'
      };
    }
    if (path.contains('/cart/coupon/apply')) {
      return {
        'status': 1,
        'message': 'تم تطبيق كود الخصم بنجاح',
        'discount': 50,
        'total': 0
      };
    }
    if (path.contains('/cart/remove')) {
      return {'status': 1, 'removed': true, 'message': 'تم حذف العنصر'};
    }
    if (path.contains('/cart')) {
      return {
        'status': 1,
        'count': 0,
        'subtotal': 0,
        'discount': 0,
        'total': 0,
        'items': []
      };
    }

    // 10. WISHLIST & BOOKING HISTORY & NOTIFICATIONS
    if (path.contains('/user/wishlist')) {
      return {'status': 1, 'total': 0, 'total_pages': 1, 'data': []};
    }
    if (path.contains('/user/booking-history') || path.contains('/my-orders')) {
      return {'status': 1, 'total': 0, 'data': []};
    }
    if (path.contains('/user/tickets') || path.contains('/my-tickets')) {
      return {'status': 1, 'total': 0, 'data': []};
    }
    if (path.contains('/notifications')) {
      return {'status': 1, 'total': 0, 'data': []};
    }

    return null;
  }
}
