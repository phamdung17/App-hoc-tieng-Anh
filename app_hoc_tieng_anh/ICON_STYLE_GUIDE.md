# Quy chuẩn icon và thiết kế giao diện LingoUp

> Tài liệu này là quy chuẩn bắt buộc khi tạo hoặc chỉnh sửa giao diện Flutter trong dự án.

## 1. Nguồn icon duy nhất

- Dùng **Lucide** thông qua package `lucide_icons_flutter` đã khai báo trong `pubspec.yaml`.
- Import từ `package:lucide_icons_flutter/lucide_icons.dart` và hiển thị bằng widget Flutter `Icon`.
- Không tự vẽ, tự tạo, sinh bằng AI, chép SVG từ nguồn khác, dùng emoji làm icon hoặc trộn thêm bộ icon khác.
- Không dùng `CustomPainter`, ký tự Unicode, hình ghép từ `Container`/`Text` hay asset tải rời để giả lập icon.
- Logo LingoUp, mascot cú và hình minh họa sản phẩm là **brand asset**, không phải icon; giữ chúng ở dạng asset riêng.
- Icon SVG Lucide đang có từ các frame Figma được xem là asset cũ. Không thêm SVG icon mới; khi chỉnh sửa màn hình cũ, ưu tiên chuyển sang package Lucide.
- Nếu không tìm thấy icon phù hợp, tra cứu Lucide trước. Chọn icon gần nghĩa nhất; không tự chế icon thay thế. Nếu icon đó không thể hiện đúng ý nghĩa, cập nhật thiết kế hoặc đề xuất bổ sung vào design system.

Ví dụ:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

Icon(
  LucideIcons.messagesSquare,
  size: 24,
  color: AppColors.textSecondary,
)
```

## 2. Quy tắc chọn và dùng icon

- Chọn icon theo **ý nghĩa của hành động hoặc nội dung**, không chỉ theo hình dáng.
- Một ý nghĩa phải dùng cùng một icon trong toàn app. Ví dụ: quay lại luôn dùng `arrowLeft`; tìm kiếm luôn dùng `search`.
- Ưu tiên tên icon Lucide dễ nhận biết; tránh đổi icon giữa các màn chỉ để trang trí.
- Icon là thành phần hỗ trợ nội dung. Không dùng icon để thay thế nhãn quan trọng hoặc thông báo bằng chữ.
- Không đổi độ dày nét, không phối nhiều phong cách outline/filled và không thêm hiệu ứng làm icon lệch khỏi bộ Lucide.
- Trạng thái như đang chọn, bị khóa hoặc lỗi được thể hiện bằng token màu và nền của design system; không đổi sang bộ icon khác.

## 3. Kích thước, màu và vùng chạm

- Kích thước mặc định: **24 px**.
- Dùng **16–20 px** cho icon phụ trong dòng văn bản hoặc nhãn nhỏ; dùng **28–32 px** cho điểm nhấn lớn khi thiết kế yêu cầu.
- Dùng màu từ `AppColors` trong `lib/core/theme/app_theme.dart`. Không tự thêm mã màu trực tiếp cho icon.
- Màu tham khảo: nội dung chính `AppColors.textPrimary`, nội dung phụ `AppColors.textSecondary`, trạng thái thương hiệu `AppColors.primaryDark`, điểm nhấn `AppColors.coral`, lỗi `AppColors.error`.
- Icon có thao tác phải nằm trong vùng chạm tối thiểu **48 × 48 px** (hoặc theo kích thước accessibility của nền tảng), dù hình icon nhỏ hơn.
- Icon đứng riêng mà không có nhãn phải có `tooltip` hoặc nhãn hỗ trợ truy cập phù hợp.

## 4. Tuân thủ design system

- Trước khi thêm style mới, kiểm tra `AppColors`, `AppRadii`, `AppTextStyles` và `AppTheme` trong `lib/core/theme/app_theme.dart`.
- Dùng token hiện có cho màu, khoảng cách, bo góc, chữ và trạng thái. Không tạo màu, kích thước hoặc kiểu nét riêng lẻ chỉ cho một icon.
- Giữ icon trong đúng bố cục Figma: căn hàng, khoảng cách với nhãn, kích thước vùng chứa, nền và trạng thái chọn phải đồng nhất.
- Icon của cùng nhóm chức năng phải có cùng kích thước, cách căn và màu theo trạng thái.
- Khi thiết kế Figma và implementation khác nhau, dùng Figma làm nguồn tham chiếu cho bố cục; ánh xạ icon sang Lucide và giữ nguyên các token của design system.
- Mọi thay đổi tạo token mới hoặc ngoại lệ cho quy chuẩn cần được phản ánh lại trong design system và tài liệu này.

## 5. Registry icon của ứng dụng

- Màn hình nên lấy icon qua registry tập trung tại `lib/core/icons/app_icons.dart` khi registry được tạo.
- Registry ánh xạ tên nghiệp vụ ổn định sang icon Lucide, ví dụ `AppIcons.search`, `AppIcons.back`, `AppIcons.review`.
- Không khai báo lại mapping khác nhau trong từng feature cho cùng một ý nghĩa.
- Khi thêm icon mới, tìm kiếm registry trước; nếu chưa có, thêm mapping ở một nơi và dùng mapping đó trên toàn app.

Ví dụ mapping:

```dart
abstract final class AppIcons {
  static const back = LucideIcons.arrowLeft;
  static const search = LucideIcons.search;
  static const review = LucideIcons.repeat2;
}
```

Tên biểu tượng phải được xác nhận trong API/autocomplete của phiên bản `lucide_icons_flutter` đang khóa trong `pubspec.lock`.

## 6. Checklist khi review giao diện

- [ ] Icon thuộc Lucide và được gọi từ `lucide_icons_flutter` (hoặc là brand asset được quy định).
- [ ] Không có icon tự vẽ, emoji, SVG icon tải rời hoặc icon từ bộ khác.
- [ ] Ý nghĩa icon nhất quán với các màn còn lại và đã kiểm tra registry.
- [ ] Kích thước, màu, nền và khoảng cách dùng token của design system.
- [ ] Icon tương tác có vùng chạm đủ lớn và có tooltip/nhãn truy cập khi cần.
- [ ] Icon không thay thế nội dung chữ quan trọng.
