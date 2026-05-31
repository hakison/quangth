#!/bin/bash

# =================== THIẾT LẬP BIẾN ===================

# Thư mục chứa APK & ảnh trong iSH (Files → iSH → ios)
SOURCE_DIR="/root/ios"
 
# adb trong Alpine Linux (iSH)
ADB_COMMAND="/usr/bin/adb"

# Màu hiển thị
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

trap '$ADB_COMMAND disconnect >/dev/null 2>&1; exit' INT TERM

# =================== HÀM DÙNG CHUNG ===================

print_header() {
    clear
    echo -e "${GREEN}========================================================${NC}"
    echo -e "${GREEN}           Trình cài đặt S.Mihome 0946.018.018          ${NC}"
    echo -e "${GREEN}========================================================${NC}"
    echo
}



install_apk() {
    local apk_file="$1"
    if [ -f "$apk_file" ]; then
        echo -e "→ Cài ${GREEN}$apk_file${NC}"
        if $ADB_COMMAND install -r -g "$apk_file"; then
            echo -e "${GREEN}✓ Thành công${NC}"
        else
            echo -e "${RED}✗ Thất bại${NC}"
        fi
    else
        echo -e "${RED}⚠ Không thấy $apk_file${NC}"
    fi
}

# =================== KIỂM TRA MÔI TRƯỜNG ===================

check_adb



# =================== MENU 1: KẾT NỐI TV ===================

menu1() {
    while true; do
        print_header
        echo "Bật ADB Debugging trên TV Xiaomi"
        echo "TV & iPhone phải cùng Wi-Fi"
        echo

        read -p "Nhập IP TV (vd: 192.168.1.100): " RAW_IP
        [ -z "$RAW_IP" ] && continue

        DEVICE_IP="${RAW_IP}:5555"

        echo
        echo "→ Ngắt kết nối cũ"
        $ADB_COMMAND disconnect >/dev/null 2>&1

        echo "→ Kết nối tới $DEVICE_IP"
        $ADB_COMMAND connect "$DEVICE_IP"

        echo -e "${GREEN}👉 Nhấn Allow trên TV${NC}"
        sleep 8

        if $ADB_COMMAND devices | grep -q "$RAW_IP"; then
            echo -e "${GREEN}✓ Kết nối thành công${NC}"
            sleep 1
            # Lấy thông tin từ thiết bị
            MODEL=$($ADB_COMMAND -s "$RAW_IP" shell getprop ro.product.model)
            ANDROID_VER=$($ADB_COMMAND -s "$RAW_IP" shell getprop ro.build.version.release)
            SDK_VER=$($ADB_COMMAND -s "$RAW_IP" shell getprop ro.build.version.sdk)

            # Hiển thị thông tin
            echo -e "${YELLOW}---------------------------${NC}"
            echo -e "${CYAN}📱 Thiết bị:${NC} $MODEL"
            echo -e "${CYAN}🤖 Android :${NC} $ANDROID_VER (API $SDK_VER)"
            echo -e "${YELLOW}---------------------------${NC}"
            sleep 3
            menu2
            break
        else
            echo -e "${RED}✗ Kết nối thất bại${NC}"
            sleep 3
        fi
    done
}

# =================== MENU 2 ===================

menu2() {
    while true; do
        print_header
        echo -e "TV đang kết nối tại: ${GREEN}$DEVICE_IP${NC}"
        echo
        echo "-- Cài đặt giao diện --"
        echo "1. Cài androi 6-11 PROJECTIVY"
        echo "2. CÀI TIVI ANDROI XS APRO 2026"
        echo "3. Cài đặt tất cả ứng dụng (.apk) Cho QUỐC TẾ GOOGLE TV"
        echo "4. Chép tất cả ảnh nền (.jpg, .png) vào TV"
        echo "5. Khởi động lại TV (Reboot)"
        echo "6. Khởi động vào Reset Cứng"
        echo "7. Ngắt và kết nối lại TV khác"
        echo "8. XIN QUYỀN X S 2026"
        echo "0. Thoát"
        echo

        read -p "→ Nhập tùy chọn của bạn [0-6]: " CHOICE

        case $CHOICE in
            1) install_projectivy ;;
            2) install_X_S_2026 ;;
            3) install_all_apks ;;
            4) copy_wallpapers ;;
            5) reboot_tv "normal" ;;
            6) reboot_tv "recovery" ;;
            7) menu1; break ;; 
            8) permission ;; 
            0) echo "👋 Tạm biệt!"; exit 0 ;;
            *) echo -e "${YELLOW}⚠️ Lựa chọn không hợp lệ, vui lòng chọn lại.${NC}"; sleep 2 ;;
        esac
    done
}

# =================== CHỨC NĂNG ===================

# Cài đặt Projectivy Launcher và các app đi kèm
install_projectivy() {
    # 1. Cấu hình hệ thống ban đầu
    $ADB_COMMAND shell service call alarm 3 s16 Asia/Bangkok >/dev/null 2>&1
    $ADB_COMMAND shell settings put global device_locales vi-VN >/dev/null 2>&1
    $ADB_COMMAND shell settings put global sys_locale vi-VN >/dev/null 2>&1
    $ADB_COMMAND shell settings put system system_locales vi-VN >/dev/null 2>&1
    $ADB_COMMAND shell settings put global heads_up_notifications_enabled 0 >/dev/null 2>&1
    $ADB_COMMAND shell settings put global stay_on_while_plugged_in 3 >/dev/null 2>&1

    echo "🚀 Bắt đầu cài đặt Projectivy Launcher..."
    install_apk "p.apk" >/dev/null 2>&1

    # Đặt Projectivy làm Launcher mặc định
    $ADB_COMMAND shell monkey -p com.spocky.projengmenu -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
    $ADB_COMMAND shell am start -n com.spocky.projengmenu/.ui.home.MainActivity >/dev/null 2>&1
    $ADB_COMMAND shell cmd package set-home-activity com.spocky.projengmenu/.ui.home.MainActivity >/dev/null 2>&1

    # Danh sách app rác cần gỡ bỏ (Đã loại bỏ com.android.tv.settings để không treo TV)
    apps="com.mitv.tvhome com.android.tv.settings com.mitv.gallery com.xiaomi.tweather  com.mitv.screensaver \
       com.xiaomi.mitv.shop com.duokan.videodaily com.xiaomi.tv.gallery \
       com.mitv.cloudcontrol com.miui.tv.analytics com.xiaomi.voicecontrol \
       com.xiaomi.mitv.upgrade com.xiaomi.mitv.appstore com.xiaomi.mitv.calendar \
       com.xiaomi.mitv.handbook com.xiaomi.screenrecorder com.sohu.inputmethod.sogou.tv \
       com.xiaomi.mitv.karaoke.service com.xiaomi.mitv.hyper.screensaver"

    # Chuyển vòng lặp sang dạng tương thích POSIX shell (iSH/Alpine)
    for app in $apps; do
        $ADB_COMMAND shell pm disable-user --user 0 "$app" >/dev/null 2>&1
    done

    # Danh sách các app phụ trợ cần cài
    apks_to_install="
      mstore.apk 
      keyboard.apk 
      katniss_2.2.0.apk 
      dl.apk quantv.apk 
      an.apk 
      youtube.apk 
      cotivi.apk 
      imedia.apk"

    echo "🚀 Bắt đầu cài đặt các ứng dụng phụ trợ..."
    for apk in $apks_to_install; do
        install_apk "$apk" >/dev/null 2>&1
    done

    # Push file cấu hình và hình nền
    $ADB_COMMAND push projectivy.plbackup /sdcard/Download >/dev/null 2>&1
    copy_wallpapers

    # BƯỚC 5: CẤP QUYỀN ỨNG DỤNG (Đã tối ưu hóa thuật toán hiển thị cho iSH)
    echo "${YELLOW}🔑 BƯỚC 5: ĐANG CẤP QUYỀN ỨNG DỤNG...${NC}"
    
       pkg="com.spocky.projengmenu"
    
    appops_perms="REQUEST_INSTALL_PACKAGES WRITE_SETTINGS MANAGE_EXTERNAL_STORAGE"
    
    runtime_perms="android.permission.READ_EXTERNAL_STORAGE \
       android.permission.WRITE_EXTERNAL_STORAGE \
       android.permission.READ_MEDIA_IMAGES \
       android.permission.READ_MEDIA_VIDEO \
       android.permission.READ_MEDIA_AUDIO \
       android.permission.WRITE_SECURE_SETTINGS"

    # Xử lý cấp quyền từ iSH shell
    echo "  [████████████████████] 100% | ${CYAN}Đang cấu quyền cho:${NC} $pkg"

    for perm in $appops_perms; do
        $ADB_COMMAND shell appops set "$pkg" "$perm" allow >/dev/null 2>&1
    done

    for perm in $runtime_perms; do
        $ADB_COMMAND shell pm grant "$pkg" "$perm" >/dev/null 2>&1
    done

    $ADB_COMMAND shell am force-stop "$pkg" >/dev/null 2>&1
    sleep 1
    
    echo "${GREEN}✅ Đã cấp quyền và đồng bộ hóa ứng dụng thành công!${NC}"

    # Cấu hình quyền và dịch vụ trợ năng (GIỮ NGUYÊN TOÀN BỘ LỆNH - ĐÃ XÓA DẤU PHẨY LỖI)
    for cmd in \
        "appops set com.spocky.projengmenu REQUEST_INSTALL_PACKAGES allow" \
        "pm grant com.mitv.shareds android.permission.WRITE_SECURE_SETTINGS" \
        "pm grant com.mitv.shareds android.permission.CHANGE_CONFIGURATION" \
        "pm grant com.spocky.projengmenu android.permission.WRITE_EXTERNAL_STORAGE" \
        "pm grant com.spocky.projengmenu android.permission.READ_EXTERNAL_STORAGE" \
        "pm grant com.spocky.projengmenu android.permission.WRITE_SECURE_SETTINGS" \
        "appops set com.google.android.katniss SYSTEM_ALERT_WINDOW allow" \
        "cmd appops set com.spocky.projengmenu WRITE_EXTERNAL_STORAGE allow" \
        "cmd appops set com.spocky.projengmenu READ_EXTERNAL_STORAGE allow" \
        "appops set com.spocky.projengmenu REQUEST_INSTALL_PACKAGES allow" \
        "ime enable com.liskovsoft.leankeyboard/.ime.LeanbackImeService" \
        "settings put secure default_input_method com.liskovsoft.leankeyboard/.ime.LeanbackImeService" \
        "settings put secure enabled_accessibility_services com.mitv.shareds/com.mitv.shareds.HomeService" \
        "settings put secure accessibility_enabled 1" \
        "cmd package set-home-activity com.spocky.projengmenu/.ui.home.MainActivity"
    do
        $ADB_COMMAND shell "$cmd" >/dev/null 2>&1
    done

    # BƯỚC 6: TỐI ƯU HÓA HỆ THỐNG VÀ KHÓA ĐUÔI
    echo "${YELLOW}🔄 Đang ghi dữ liệu bảo mật và đồng bộ ổ cứng TV...${NC}"
    
    $ADB_COMMAND shell cmd appops write-settings >/dev/null 2>&1
    sleep 1
    $ADB_COMMAND shell settings put global install_non_market_apps 1 >/dev/null 2>&1
    sleep 1
    $ADB_COMMAND shell settings list secure >/dev/null 2>&1
    sleep 1                               
    $ADB_COMMAND shell sync >/dev/null 2>&1
    sleep 3 # Dùng sleep chuẩn của Linux thay cho time.sleep của Python
    
    echo "${GREEN}✅ Cài đặt Projectivy hoàn tất!${NC}"
    
    reboot_tv "normal"
    menu1
}

# Cài đặt X S 2026 và các app đi kèm
install_X_S_2026() {
    # 1. Cấu hình hệ thống ban đầu
    $ADB_COMMAND shell service call alarm 3 s16 Asia/Bangkok >/dev/null 2>&1
    $ADB_COMMAND shell settings put global device_locales vi-VN >/dev/null 2>&1
    $ADB_COMMAND shell settings put global sys_locale vi-VN >/dev/null 2>&1
    $ADB_COMMAND shell settings put system system_locales vi-VN >/dev/null 2>&1
    $ADB_COMMAND shell settings put global heads_up_notifications_enabled 0 >/dev/null 2>&1
    $ADB_COMMAND shell settings put global stay_on_while_plugged_in 3 >/dev/null 2>&1
    $ADB_COMMAND shell appops set com.xiaomi.voicecontrol SYSTEM_ALERT_WINDOW deny >/dev/null 2>&1
    
    echo "🚀 Bắt đầu cài đặt Projectivy Launcher..."
    install_apk "p.apk" >/dev/null 2>&1
    
    $ADB_COMMAND shell monkey -p com.spocky.projengmenu -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
    $ADB_COMMAND shell am start -n com.spocky.projengmenu/.ui.home.MainActivity >/dev/null 2>&1
    $ADB_COMMAND shell cmd package set-home-activity com.spocky.projengmenu/.ui.home.MainActivity >/dev/null 2>&1
   
    # Danh sách app rác (Chuyển sang định dạng chuỗi tương thích iSH Shell)
    apps="com.mitv.tvhome \
      com.mitv.gallery \
      com.xiaomi.tweather \
      com.mitv.screensaver \
      com.xiaomi.mitv.shop \
      com.duokan.videodaily \
      com.xiaomi.tv.gallery \
      com.mitv.cloudcontrol \
      com.miui.tv.analytics \
      com.xiaomi.voicecontrol \
      com.xiaomi.mitv.upgrade \
      com.xiaomi.mitv.appstore \
      com.xiaomi.mitv.calendar \
      com.xiaomi.mitv.handbook \
      com.xiaomi.screenrecorder \
      com.sohu.inputmethod.sogou.tv \
      com.xiaomi.mitv.karaoke.service \
      com.xiaomi.mitv.hyper.screensaver \
      com.android.tv.settings"

    for app in $apps; do
        $ADB_COMMAND shell pm disable-user --user 0 "$app" >/dev/null 2>&1
    done
  
    # Danh sách các app phụ trợ cần cài (Chuyển định dạng tương thích iSH Shell)
    apks_to_install="mstore.apk keyboard.apk katniss_2.2.0.apk dl.apk quantv.apk an.apk youtube.apk cotivi.apk imedia.apk"

    echo "🚀 Bắt đầu cài đặt các ứng dụng phụ trợ..."
    for apk in $apks_to_install; do
        install_apk "$apk"
    done
    
    $ADB_COMMAND push projectivy.plbackup /sdcard/Download >/dev/null 2>&1
    copy_wallpapers
    
    # BƯỚC 5: CẤP QUYỀN ỨNG DỤNG BẰNG TIẾN TRÌNH TRỰC QUAN (Tối ưu vòng lặp POSIX cho iSH)
    echo "${YELLOW}🔑 BƯỚC 5: ĐANG CẤP QUYỀN ỨNG DỤNG...${NC}"
    
    pkg="com.spocky.projengmenu"
    appops_perms="REQUEST_INSTALL_PACKAGES WRITE_SETTINGS MANAGE_EXTERNAL_STORAGE"
    runtime_perms="android.permission.READ_EXTERNAL_STORAGE \
      android.permission.WRITE_EXTERNAL_STORAGE \
      android.permission.READ_MEDIA_IMAGES \
      android.permission.READ_MEDIA_VIDEO \
      android.permission.READ_MEDIA_AUDIO"

    # Hiển thị thanh trạng thái tĩnh gọn gàng, không lỗi nhảy dòng trên iSH
    echo "  [████████████████████] 100% | ${CYAN}Cấp quyền:${NC} $pkg"

    for perm in $appops_perms; do
        $ADB_COMMAND shell appops set "$pkg" "$perm" allow >/dev/null 2>&1
    done

    for perm in $runtime_perms; do
        $ADB_COMMAND shell pm grant "$pkg" "$perm" >/dev/null 2>&1
    done

    $ADB_COMMAND shell am force-stop "$pkg" >/dev/null 2>&1
    sleep 1
    
    echo "${GREEN}✅ Đã cấp quyền và đồng bộ hóa ứng dụng!${NC}"

    # Cấu hình quyền và dịch vụ trợ năng (GIỮ NGUYÊN TOÀN BỘ LỆNH - ĐÃ XÓA DẤU PHẨY LỖI)
    for cmd in \
        "appops set com.spocky.projengmenu REQUEST_INSTALL_PACKAGES allow" \
        "pm grant com.mitv.shareds android.permission.WRITE_SECURE_SETTINGS" \
        "pm grant com.mitv.shareds android.permission.CHANGE_CONFIGURATION" \
        "pm grant com.spocky.projengmenu android.permission.WRITE_EXTERNAL_STORAGE" \
        "pm grant com.spocky.projengmenu android.permission.READ_EXTERNAL_STORAGE" \
        "pm grant com.spocky.projengmenu android.permission.WRITE_SECURE_SETTINGS" \
        "appops set com.google.android.katniss SYSTEM_ALERT_WINDOW allow" \
        "cmd appops set com.spocky.projengmenu WRITE_EXTERNAL_STORAGE allow" \
        "cmd appops set com.spocky.projengmenu READ_EXTERNAL_STORAGE allow" \
        "appops set com.spocky.projengmenu REQUEST_INSTALL_PACKAGES allow" \
        "ime enable com.liskovsoft.leankeyboard/.ime.LeanbackImeService" \
        "settings put secure default_input_method com.liskovsoft.leankeyboard/.ime.LeanbackImeService" \
        "settings put secure enabled_accessibility_services com.mitv.shareds/com.mitv.shareds.HomeService" \
        "settings put secure accessibility_enabled 1" \
        "cmd package set-home-activity com.spocky.projengmenu/.ui.home.MainActivity"
    do
        $ADB_COMMAND shell "$cmd" >/dev/null 2>&1
    done

    # BƯỚC 6: TỐI ƯU HÓA HỆ THỐNG VÀ KHÓA ĐUÔI
    echo "${YELLOW}🔄 Đang ghi dữ liệu bảo mật và đồng bộ ổ cứng TV...${NC}"
    
    $ADB_COMMAND shell cmd appops write-settings >/dev/null 2>&1
    sleep 0.2
    $ADB_COMMAND shell settings put global install_non_market_apps 1 >/dev/null 2>&1
    sleep 0.2
    $ADB_COMMAND shell settings list secure >/dev/null 2>&1
    sleep 0.2                               
    $ADB_COMMAND shell sync >/dev/null 2>&1
    sleep 3 

    sleep 2
    echo "${GREEN}✅ Cài đặt Projectivy hoàn tất!${NC}"
    
    reboot_tv "normal"
    menu1
}

# Sao chép ảnh nền vào TV
copy_wallpapers() {
    echo "🖼️ Bắt đầu chép ảnh nền (.jpg, .png) vào TV..."
    local count=0
    # Sử dụng vòng lặp for an toàn hơn với tên file có khoảng trắng
    for file in *.{jpg,jpeg,png,JPG,JPEG,PNG}; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            local extension="${filename##*.}"
            echo "    -> Đang chép $filename..."
            $ADB_COMMAND push "$file" "/sdcard/DCIM_${count}.${extension}"
            count=$((count + 1))
        fi
    done

    if [ "$count" -eq 0 ]; then
        echo -e "   ${YELLOW}⚠️ Không tìm thấy file ảnh nào.${NC}"
    else
        echo -e "${GREEN}✅ Đã chép $count ảnh vào thư mục /sdcard/DCIM/ trên TV.${NC}"
    fi
    sleep 3
}

# Cài đặt tất cả các file .apk trong thư mục nguồn
install_all_apks() {
    echo "🔧 Bắt đầu cài đặt tất cả các file .apk trong $SOURCE_DIR..."
    local apk_files=(*.apk)
    
    if [ ${#apk_files[@]} -eq 0 ] || [ ! -f "${apk_files[0]}" ]; then
        echo -e "   ${YELLOW}⚠️ Không tìm thấy file .apk nào.${NC}"
        sleep 3
        return
    fi

    for file in "${apk_files[@]}"; do
        install_apk "$file"
    done
    
    for cmd in \
        "settings put global stay_on_while_plugged_in 3" \
        "monkey -p com.spocky.projengmenu -c android.intent.category.LAUNCHER 1" \
        "am start -n com.spocky.projengmenu/.ui.home.MainActivity" \
        "cmd package set-home-activity com.spocky.projengmenu/.ui.home.MainActivity"
    do
        $ADB_COMMAND shell "$cmd" >/dev/null 2>&1
    done

    $ADB_COMMAND push projectivy.plbackup /sdcard/Download >/dev/null 2>&1


    echo -e "${GREEN}✅ Đã xử lý ${#apk_files[@]} file .apk.${NC}"
    sleep 3
    menu1
}

# xin quyền mã tivi x s sau khi tắt voice
permission() {
 $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.voicecontrol >/dev/null 2>&1
 $ADB_COMMAND shell pm enable --user 0 com.xiaomi.mitv.settings >/dev/null 2>&1
 $ADB_COMMAND shell appops set com.xiaomi.voicecontrol SYSTEM_ALERT_WINDOW deny >/dev/null 2>&1
}
# Khởi động lại TV
reboot_tv() {
    local mode="$1"
    print_header
    echo "→ Reboot TV ($mode)"

    if [ "$mode" = "recovery" ]; then
        $ADB_COMMAND reboot recovery >/dev/null 2>&1 &
    else
        $ADB_COMMAND reboot >/dev/null 2>&1 &
    fi

    echo "→ Đã gửi lệnh reboot (không chờ phản hồi)"
    sleep 1

    echo "→ Ngắt kết nối ADB"
    $ADB_COMMAND disconnect >/dev/null 2>&1

    echo "→ Chờ TV khởi động lại..."
    sleep 8

    echo "→ Quay về Menu kết nối"
    sleep 1
    menu1
}

# =================== START ===================
menu1


