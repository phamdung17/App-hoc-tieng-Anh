# File Map – Flutter App học tiếng Anh + AI

Tài liệu này mô tả cấu trúc Flutter FE trong `lib/`, trách nhiệm của các nhóm file và 18 giao diện. Backend FastAPI hiện ở project bên cạnh `../backend_app/backend/`; README BE nằm tại `../backend_app/backend/README.md`. Các thư mục mới là bộ khung tài liệu, chưa có logic chạy được; `lib/main.dart` hiện vẫn là Flutter counter demo.

## Nguyên tắc tổ chức

- Chia theo tính năng trong `features/`, tránh gom UI, gọi API và nghiệp vụ vào một file.
- `presentation/` hiển thị giao diện và nhận thao tác; `domain/` chứa quy tắc/kiểu nghiệp vụ; `data/` giao tiếp API và chuyển đổi dữ liệu.
- `core/` chỉ chứa hạ tầng hoặc thành phần dùng chung cho nhiều tính năng.
- File màn hình dùng hậu tố `_page.dart`; widget nhỏ dùng tên mô tả + `_widget.dart` khi cần; model/DTO/repository/API đặt tên theo vai trò.
- Không tạo một file cho mỗi nút hoặc dòng UI. Tách widget khi có logic riêng, được tái sử dụng hoặc giúp page dễ đọc.

## Cấu trúc cấp ứng dụng

| Đường dẫn | Trạng thái | Trách nhiệm |
|---|---|---|
| `lib/main.dart` | Đang có | Điểm khởi chạy. Chỉ khởi tạo ứng dụng và gọi `runApp`; không chứa màn hình nghiệp vụ. Hiện đang là Flutter counter demo và sẽ được thay khi dựng app thật. |
| `lib/app/app.dart` | Dự kiến | Cấu hình `MaterialApp`, theme, locale, route và màn hình khởi đầu. |
| `lib/app/router.dart` | Dự kiến | Định nghĩa tên/đường dẫn route, tham số điều hướng, redirect sau đăng nhập và chặn route cần xác thực. |
| `lib/app/navigation/main_shell.dart` | Dự kiến | Khung sau đăng nhập: 4 tab Lộ trình, Kho từ, Ôn tập, Hồ sơ và nút Camera nổi bật. Giữ trạng thái tab khi chuyển qua lại nếu cần. |

## Hạ tầng dùng chung – `lib/core/`

| Thư mục / file dự kiến | Trách nhiệm |
|---|---|
| `core/config/app_config.dart` | Cấu hình môi trường và `baseUrl` backend; không đặt token bí mật trong ứng dụng. |
| `core/network/api_client.dart` | Cấu hình HTTP client, timeout, header và gửi access token. |
| `core/network/auth_interceptor.dart` | Gắn token, xử lý 401/refresh token và kết thúc phiên khi refresh thất bại. |
| `core/network/api_error.dart` | Chuẩn hóa lỗi backend `{code, message, details}` để UI xử lý nhất quán. |
| `core/storage/token_storage.dart` | Lưu/xóa access và refresh token an toàn trên thiết bị. |
| `core/storage/preferences_storage.dart` | Lưu tùy chọn cục bộ không nhạy cảm như theme hoặc âm thanh. Dữ liệu hồ sơ đồng bộ cần đi qua API. |
| `core/theme/app_theme.dart` | Màu, kiểu chữ, hình dạng nút/thẻ và cấu hình theme sáng/tối. |
| `core/widgets/app_button.dart` | Nút dùng chung nếu các màn hình cần cùng kiểu hiển thị/trạng thái tải. |
| `core/widgets/loading_view.dart` | Trạng thái đang tải dùng chung. |
| `core/widgets/error_view.dart` | Trạng thái lỗi có nội dung và hành động thử lại. |
| `core/widgets/empty_state.dart` | Khung rỗng dùng chung; nội dung và nút hành động do từng tính năng truyền vào. |
| `core/errors/` | Các kiểu lỗi/ánh xạ lỗi dùng chung nếu không thuộc riêng một tính năng. |

Các file trên chỉ nên được tạo khi cần triển khai tương ứng; `.gitkeep` hiện tại chỉ giữ chỗ cho thư mục.

## Tính năng và file dự kiến

### 1. Tài khoản – `lib/features/auth/`

| Đường dẫn dự kiến | Trách nhiệm |
|---|---|
| `data/auth_api.dart` | Gọi `/auth/guest`, `/auth/register`, `/auth/login`, `/auth/social`, `/auth/link`, verify/resend, quên/đặt lại mật khẩu và logout. |
| `data/auth_dto.dart` | Chuyển JSON auth/profile thành dữ liệu ứng dụng; gồm trạng thái guest và email đã xác minh. |
| `data/auth_repository_impl.dart` | Thực thi hợp đồng repository bằng API và lưu token. |
| `domain/auth_repository.dart` | Hợp đồng nghiệp vụ đăng nhập, đăng ký, khách, liên kết tài khoản và đăng xuất. |
| `domain/app_user.dart` | Người dùng hiện tại, trạng thái khách và quyền AI theo trạng thái xác minh. |
| `presentation/pages/welcome_page.dart` | **Giao diện 01:** logo/linh vật, kiểm tra phiên; vào app nếu đã có phiên, hoặc chuyển tới khảo sát/đăng nhập. |
| `presentation/pages/onboarding_survey_page.dart` | **Giao diện 02:** 3 bước chọn mục tiêu, trình độ và phút học mỗi ngày; lưu cấu hình trước khi đi tiếp. |
| `presentation/pages/auth_page.dart` | **Giao diện 03:** tab đăng nhập/đăng ký, email, mật khẩu, Google/Apple và luồng quên mật khẩu. |
| `presentation/pages/email_verification_page.dart` | Màn trạng thái/xác minh email và gửi lại thư xác minh khi backend yêu cầu; có thể gộp vào auth page nếu UI đơn giản. |
| `presentation/widgets/auth_form.dart` | Form tái sử dụng cho đăng nhập/đăng ký, validation và trạng thái gửi. |
| `presentation/widgets/guest_ai_gate_dialog.dart` | Giải thích cần tài khoản/xác minh email khi khách hoặc tài khoản chưa xác minh mở tính năng AI. |

### 2. Học và lộ trình – `lib/features/learning/`

| Đường dẫn dự kiến | Trách nhiệm |
|---|---|
| `data/learning_api.dart` | Lấy `/path`, `/lessons/{id}` và gửi kết quả hoàn thành bài. |
| `data/learning_dto.dart` | DTO cho unit, lesson, exercise và kết quả bài học. |
| `data/learning_repository_impl.dart` | Đọc/ghi dữ liệu học thông qua API. |
| `domain/learning_repository.dart` | Hợp đồng tải lộ trình, bài học và nộp attempt. |
| `domain/lesson.dart` | Kiểu dữ liệu bài học và danh sách bài tập. |
| `domain/exercise.dart` | Kiểu dữ liệu bài tập theo `image_choice`, `word_bank`, `listening`, `speaking`, `match_pairs`. |
| `domain/lesson_attempt.dart` | Câu trả lời, số lần thử, thời gian và trạng thái attempt. |
| `presentation/pages/learning_path_page.dart` | **Giao diện 04:** bản đồ unit/bài học, Streak, XP và mục tiêu hôm nay; mở tóm tắt bài và bắt đầu bài. |
| `presentation/pages/lesson_page.dart` | **Giao diện 05:** khung bài học dùng chung, tiến độ, đóng bài, kiểm tra câu trả lời, phản hồi đúng/sai và hàng đợi làm lại câu sai. |
| `presentation/pages/lesson_result_page.dart` | **Giao diện 11:** kết quả XP/độ chính xác/thời gian, streak và nút quay về lộ trình. |
| `presentation/exercises/image_choice_exercise.dart` | **Giao diện 06:** chọn một hình phù hợp với từ/câu, hiển thị IPA và phát âm. |
| `presentation/exercises/word_bank_exercise.dart` | **Giao diện 07:** sắp thẻ từ thành câu; thêm/bỏ từ khỏi vùng câu trả lời. |
| `presentation/exercises/listening_exercise.dart` | **Giao diện 08:** phát âm chuẩn/chậm, điền từ hoặc nhập câu nghe được. |
| `presentation/exercises/speaking_exercise.dart` | **Giao diện 09:** thu giọng nói, trạng thái nhận diện, hiển thị kết quả và cho phép bỏ qua khi không tiện nói. |
| `presentation/exercises/match_pairs_exercise.dart` | **Giao diện 10:** ghép cặp từ Anh–Việt, trạng thái đúng/sai và hoàn tất khi ghép đủ. |
| `presentation/widgets/lesson_progress_bar.dart` | Thanh tiến độ và trạng thái câu trong lesson shell. |
| `presentation/widgets/answer_feedback_sheet.dart` | Banner/bottom sheet phản hồi, đáp án đúng và giải thích. |
| `presentation/widgets/exit_lesson_dialog.dart` | Xác nhận khi rời bài đang làm dở. |
| `presentation/widgets/unit_lesson_node.dart` | Nút bài học trên bản đồ theo trạng thái khóa/đang học/đã xong. |

### 3. Quét ảnh AI – `lib/features/scan/`

| Đường dẫn dự kiến | Trách nhiệm |
|---|---|
| `data/scan_api.dart` | Lấy quota/lịch sử, gửi ảnh tới `/scans`, đọc scan và sửa/báo nhãn. |
| `data/scan_dto.dart` | Chuyển JSON scan, bounding box, kết quả nhận diện và quota thành model. |
| `data/image_preparation_service.dart` | Kiểm tra định dạng, resize/nén ảnh trước khi upload; không chứa widget camera. |
| `data/scan_repository_impl.dart` | Ghép API và dịch vụ xử lý ảnh thành thao tác scan. |
| `domain/scan_repository.dart` | Hợp đồng lấy quota, quét, sửa nhãn, lưu/báo kết quả. |
| `domain/scan_result.dart` | Ảnh scan và danh sách vật thể/nhãn/bounding box. |
| `presentation/pages/scan_camera_page.dart` | **Giao diện 12:** camera/thư viện, đèn flash, quota hôm nay và lịch sử gần đây. Kiểm tra quyền trước khi mở camera. |
| `presentation/pages/scan_result_page.dart` | **Giao diện 13:** ảnh có bounding box, chi tiết nhãn, phát âm, sửa/báo sai và lưu từ. |
| `presentation/widgets/camera_viewfinder.dart` | Khung xem camera và dấu căn vật thể. |
| `presentation/widgets/detection_overlay.dart` | Vẽ bounding box lên ảnh theo tọa độ chuẩn hóa 0..1. |
| `presentation/widgets/detected_word_card.dart` | Nội dung từ được chọn: IPA, nghĩa, ví dụ và thao tác lưu. |
| `presentation/widgets/scan_quota_badge.dart` | Huy hiệu lượt còn lại; dữ liệu lấy từ backend, không tự làm nguồn quota. |

### 4. Kho từ – `lib/features/vocabulary/`

| Đường dẫn dự kiến | Trách nhiệm |
|---|---|
| `data/vocabulary_api.dart` | Gọi danh sách `/vocab`, chi tiết, cập nhật, xóa và thao tác lưu từ scan. |
| `data/vocabulary_dto.dart` | Chuyển dữ liệu từ vựng, ảnh, ghi chú và mức độ ôn. |
| `data/vocabulary_repository_impl.dart` | Triển khai truy vấn/tìm kiếm/lọc và cập nhật kho từ. |
| `domain/vocabulary_repository.dart` | Hợp đồng đọc/sửa/xóa từ đã lưu. |
| `domain/vocabulary_word.dart` | Từ, nghĩa, IPA, ví dụ, chủ đề, ảnh và ghi chú cá nhân. |
| `presentation/pages/vocabulary_page.dart` | **Giao diện 14:** tìm kiếm, lọc theo chủ đề/mức độ, lưới từ, trạng thái rỗng và lối tắt ôn. |
| `presentation/pages/vocabulary_detail_page.dart` | **Giao diện 15:** ảnh, phát âm, nghĩa/ví dụ, mức độ thuộc, ghi chú, sửa và xóa. |
| `presentation/widgets/vocabulary_card.dart` | Thẻ từ trong lưới kho từ. |
| `presentation/widgets/vocabulary_filters.dart` | Ô tìm kiếm và chip chủ đề/mức độ. |

### 5. Ôn tập – `lib/features/review/`

| Đường dẫn dự kiến | Trách nhiệm |
|---|---|
| `data/review_api.dart` | Lấy danh sách câu sai, phiên flashcard, gửi câu trả lời và hoàn tất phiên. |
| `data/review_dto.dart` | DTO cho câu sai, thẻ ôn và kết quả phiên. |
| `data/review_repository_impl.dart` | Giao tiếp API review/practice. |
| `domain/review_repository.dart` | Hợp đồng lấy nội dung đến hạn và ghi nhận câu trả lời. |
| `domain/review_session.dart` | Trạng thái phiên ôn và thứ tự thẻ/câu. |
| `presentation/pages/practice_hub_page.dart` | **Giao diện 16:** hộp thư lỗi sai, luyện nghe/nói nhanh và lối tắt flashcard. |
| `presentation/pages/flashcard_page.dart` | **Giao diện 17:** lật thẻ, tự đánh giá nhớ/quên, quiz chọn đáp án hoặc gõ từ. |
| `presentation/widgets/flashcard.dart` | Thẻ hai mặt gồm ảnh và thông tin từ. |
| `presentation/widgets/review_rating_buttons.dart` | Các lựa chọn tự đánh giá; FE gửi kết quả, backend quyết định lịch SRS. |

### 6. Hồ sơ và cài đặt – `lib/features/profile/`

| Đường dẫn dự kiến | Trách nhiệm |
|---|---|
| `data/profile_api.dart` | Lấy/cập nhật `/me`, đăng ký device token nếu có push, yêu cầu xóa tài khoản. |
| `data/profile_dto.dart` | Chuyển dữ liệu hồ sơ/cài đặt từ JSON. |
| `data/profile_repository_impl.dart` | Lưu thay đổi hồ sơ qua API. |
| `domain/profile_repository.dart` | Hợp đồng đọc và cập nhật hồ sơ. |
| `domain/user_profile.dart` | Tên, email, ảnh đại diện, mục tiêu, giờ nhắc, theme và âm thanh. |
| `presentation/pages/profile_page.dart` | **Giao diện 18:** thông tin cá nhân, thống kê, lịch streak, cài đặt, đăng xuất và xóa tài khoản. |
| `presentation/widgets/streak_calendar.dart` | Lịch hoạt động theo tháng từ dữ liệu backend. |
| `presentation/widgets/profile_settings_section.dart` | Các lựa chọn theme, âm thanh, mục tiêu và giờ nhắc. |
| `presentation/widgets/delete_account_dialog.dart` | Xác nhận xóa tài khoản theo các bước UI và gọi API phù hợp. |

### 7. Tiến độ – `lib/features/progress/`

| Đường dẫn dự kiến | Trách nhiệm |
|---|---|
| `data/progress_api.dart` | Lấy `/progress/summary` và `/progress/calendar`. |
| `data/progress_dto.dart` | Chuyển XP, streak, mục tiêu ngày và dữ liệu lịch. |
| `data/progress_repository_impl.dart` | Tải dữ liệu tiến độ từ backend. |
| `domain/progress_repository.dart` | Hợp đồng truy vấn tiến độ. |
| `domain/progress_summary.dart` | Model tổng hợp XP, streak và mục tiêu ngày. |
| `presentation/widgets/daily_goal_card.dart` | Thẻ XP/mục tiêu hôm nay dùng trên lộ trình. |
| `presentation/widgets/xp_streak_header.dart` | Hiển thị XP và streak trên màn hình lộ trình. |

Tiến độ có thể gộp vào `learning/` lúc ban đầu nếu chỉ có vài widget; tách riêng khi nhiều màn hình cần dùng cùng dữ liệu tiến độ.

## Bản đồ 18 giao diện

| Số | Tên giao diện | File page dự kiến | Tính năng chính |
|---:|---|---|---|
| 01 | Chào mừng / Splash | `auth/presentation/pages/welcome_page.dart` | Kiểm tra phiên và điều hướng. |
| 02 | Khảo sát cá nhân hóa | `auth/presentation/pages/onboarding_survey_page.dart` | Mục tiêu, trình độ, thời lượng học. |
| 03 | Đăng nhập / Đăng ký | `auth/presentation/pages/auth_page.dart` | Email, mật khẩu, mạng xã hội, quên mật khẩu. |
| 04 | Bản đồ lộ trình | `learning/presentation/pages/learning_path_page.dart` | Unit/bài, XP, streak, mục tiêu và mở bài. |
| 05 | Khung bài học | `learning/presentation/pages/lesson_page.dart` | Điều phối dạng bài, chấm/nhận phản hồi, làm lại câu sai. |
| 06 | Chọn hình ảnh | `learning/presentation/exercises/image_choice_exercise.dart` | Chọn hình theo từ/câu. |
| 07 | Ghép từ thành câu | `learning/presentation/exercises/word_bank_exercise.dart` | Sắp từ thành câu. |
| 08 | Nghe và điền từ | `learning/presentation/exercises/listening_exercise.dart` | Nghe chuẩn/chậm, điền hoặc chép câu. |
| 09 | Luyện phát âm | `learning/presentation/exercises/speaking_exercise.dart` | Thu giọng nói và đánh giá. |
| 10 | Ghép cặp thẻ từ | `learning/presentation/exercises/match_pairs_exercise.dart` | Ghép từ Anh–Việt. |
| 11 | Tổng kết bài | `learning/presentation/pages/lesson_result_page.dart` | Kết quả, XP, streak, quay về lộ trình. |
| 12 | Máy ảnh / tải ảnh AI | `scan/presentation/pages/scan_camera_page.dart` | Chụp/chọn ảnh và xem quota. |
| 13 | Kết quả nhận diện | `scan/presentation/pages/scan_result_page.dart` | Bounding box, chi tiết từ, sửa và lưu. |
| 14 | Kho từ vựng | `vocabulary/presentation/pages/vocabulary_page.dart` | Tìm kiếm, lọc và mở từ. |
| 15 | Chi tiết từ | `vocabulary/presentation/pages/vocabulary_detail_page.dart` | Phát âm, ghi chú, sửa/xóa. |
| 16 | Trung tâm ôn tập | `review/presentation/pages/practice_hub_page.dart` | Lỗi sai, nghe/nói nhanh và flashcard. |
| 17 | Flashcard / Quiz | `review/presentation/pages/flashcard_page.dart` | Ôn thẻ và kiểm tra từ. |
| 18 | Hồ sơ / Thống kê / Cài đặt | `profile/presentation/pages/profile_page.dart` | Hồ sơ, lịch streak, nhắc học và cài đặt. |

## Hộp thoại và trạng thái giao diện

Đây là thành phần UI, không tính thành page độc lập:

- Dialog xin quyền camera/thư viện/micro/thông báo: đặt gần tính năng sở hữu luồng quyền (`scan` hoặc `learning`); giải thích trước khi gọi quyền hệ điều hành.
- Dialog thoát bài học: `learning/presentation/widgets/exit_lesson_dialog.dart`.
- Sửa nhãn/báo sai: thành phần của trang kết quả scan; lựa chọn nhãn phải khớp quy tắc backend.
- Trạng thái rỗng kho từ và hộp lỗi sai: dùng `core/widgets/empty_state.dart` với nội dung theo feature.
- Lỗi mạng, lỗi scan, hết quota: map mã lỗi backend ở repository/controller và hiển thị trong UI của tính năng; có hành động thử lại khi phù hợp.

## Quy ước kết nối Backend

- Backend là nguồn chính cho XP, streak, quota scan, quyền AI, tiến độ và lịch ôn SRS.
- API scan yêu cầu tài khoản đã xác minh; UI chỉ giải thích/trình bày trạng thái, không thay thế kiểm tra quyền server.
- Các mã nghiệp vụ như `AUTH_REQUIRED_FOR_AI`, `EMAIL_NOT_VERIFIED`, `SCAN_LIMIT_REACHED`, `AI_TEMPORARILY_UNAVAILABLE`, `SCAN_FAILED`, `WORD_EXISTS` nên được chuyển thành trạng thái/thông báo dễ hiểu ở tầng presentation.
- Với bài học, FE gửi câu trả lời/attempt; backend tự chấm các loại đã quy định. Không dựa vào điểm do UI tự tính làm kết quả chính thức.
- Trước khi triển khai cần thống nhất các điểm khác nhau giữa hai tài liệu: XP lưu từ (+5 ở FE, +10 ở BE), ngưỡng phát âm (75% ở FE, 0.6 ở BE), và sửa nhãn (nhập tự do ở FE, chọn từ có sẵn ở BE).

## Trạng thái hiện tại

- Đã có: `lib/main.dart` (Flutter counter demo).
- Đã tạo: thư mục khung trong `lib/app`, `lib/core`, `lib/features/*`; `.gitkeep` chỉ có tác dụng giữ thư mục trống trong Git.
- Chưa có: các file dự kiến nêu trong bản đồ, luồng giao diện, API client và nghiệp vụ.

## Hướng dẫn plugin Flutter theo tính năng

Các plugin dưới đây là lựa chọn dự kiến theo yêu cầu app. Chỉ thêm dependency vào `pubspec.yaml` khi bắt đầu triển khai tính năng cần nó; trước đó kiểm tra lại phiên bản, Android/iOS setup và quyền hệ thống.

| Plugin | Tính năng / giao diện | Mục đích |
|---|---|---|
| `camera` | `scan`, giao diện 12 | Preview camera trực tiếp, chụp ảnh, flash. |
| `image_picker` | `scan`, giao diện 12 | Chọn ảnh từ thư viện. |
| `flutter_image_compress` | `scan/data` | Resize/nén ảnh trước upload; Backend vẫn kiểm tra và xử lý ảnh. |
| `cached_network_image` | `learning`, `scan`, `vocabulary`, `review` | Ảnh bài học và ảnh từ vựng có placeholder/lỗi tải. Với presigned URL, dùng ID ổn định làm cache key nếu phù hợp và tải lại URL hết hạn. |
| `speech_to_text` | `learning`, giao diện 09 | Nhận dạng lời nói trên thiết bị để chấm câu đọc. |
| `flutter_tts` | `learning`, `scan`, `vocabulary`, giao diện 06/08/13–15 | Đọc từ/câu và tốc độ chậm; bài nghe seed sẵn nội dung, không sinh câu tự động. |
| `just_audio` | `learning`, giao diện 08 | Phát file audio thu sẵn nếu nội dung bài nghe cần audio cố định. Chỉ thêm nếu chọn audio file; không cài đồng thời `audioplayers` nếu không có nhu cầu riêng. |
| `table_calendar` | `profile`, giao diện 18 | Lịch heatmap streak theo dữ liệu Backend. |
| `flutter_local_notifications` | `profile`, giao diện 18 | Lên lịch nhắc học cục bộ hằng ngày. |
| `firebase_messaging` | `profile`/khởi tạo app | Nhận push notification do Backend gửi qua FCM; phối hợp local notification khi cần. |
| `permission_handler` | `scan`, `learning`, `profile` | Xin/kiểm tra quyền camera, micro và thông báo; mở App Settings khi bị từ chối vĩnh viễn. |
| `flutter_secure_storage` | `core/storage` | Lưu token auth an toàn trên thiết bị. |
| `flutter_animate` | `core/widgets`, `learning` | Animation nhỏ ở onboarding, phản hồi và tổng kết. |
| `shimmer` | `core/widgets` | Skeleton loading cho lộ trình, kho từ và hồ sơ. |

### Chưa đưa vào phạm vi hiện tại

- Dùng widget Flutter có sẵn cho bottom navigation, badge, calendar date picker, snackbar và rung nhẹ (`NavigationBar`, `Badge`, `CalendarDatePicker`, `SnackBar`, `HapticFeedback`) trước khi thêm package chuyên biệt.
- Chưa cần `live_activities`, video/ringtone/callkit, file/PDF viewer, payment, location/map, barcode/document scanner.
- Không dùng `OneSignal` cùng FCM trong cùng luồng hiện tại; Flutter không gọi Gemini/OpenAI trực tiếp. Nhận diện ảnh do Backend gọi Gemini API; không có YOLO container trong kiến trúc mới.
- `connectivity_plus`, carousel, URL launcher và các plugin tiện ích khác chỉ thêm khi có yêu cầu sản phẩm cụ thể.

Xem README trong từng feature để biết plugin dự kiến dùng ở tầng/thư mục nào. Danh sách này là hướng dẫn kiến trúc, chưa có nghĩa plugin đã được cài.


## Backend – project bên cạnh `../backend_app/backend/`

Backend nằm trong project sibling `../backend_app/backend/`, tách khỏi Flutter project. Stack: FastAPI + Pydantic v2, PostgreSQL + SQLAlchemy 2.0, Alembic, Redis, ARQ; Gemini API được gọi từ Backend. Không có YOLO model container.

```text
backend/
├── README.md
├── app/
│   ├── core/                 # config, security, deps, errors
│   ├── modules/              # auth, users, content, learning, progress,
│   │                         # scan, vocab, review, practice, notifications
│   ├── integrations/         # gemini_client, storage, mailer, FCM
│   ├── workers/             # ARQ jobs nền
│   └── seed_data/            # words, courses, exercises đã duyệt
├── alembic/versions/         # database migrations
└── tests/                    # unit, integration, fixtures
```

Mỗi thư mục Backend có README riêng tại `../backend_app/backend/`. Lesson/course/exercise vẫn seed và duyệt trước; Gemini chỉ bổ sung/cache từ vựng phát sinh từ scan, không sinh lesson. Backend hiện mới gồm README và `.gitkeep`, chưa có Python files, migration thực tế, dependencies hoặc Docker Compose.

