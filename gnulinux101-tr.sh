#!/usr/bin/env bash
# Linux101: gerçek sistemden ayrılmış, Bash tabanlı eğitim terminali.
set -u
export LC_ALL=C.UTF-8
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
STATE_DIR="$SCRIPT_DIR/.linux101-tr"
LEVEL=1
DONE=0
INPUT=/dev/null
TOKENS=()
PASSWORDS=()
OP=$'\x1f'
QSTAR=$'\x1e'

say() { printf '%s\n' "$*"; }
fail() { say "Hata: $*" >&2; return 1; }

# Tek dosya dağıtımı: rehber dışarıdan okunmaz.
help_text() {
    cat <<'LINUX101_HELP'
# GNU/Linux 101 — Komut rehberi

Bu kontrollü eğitim terminalinde /home/user ve ~ oyun içindeki ev
dizinidir. Gerçek kullanıcı dosyalarınız üzerinde çalışılmaz.
yardım: rehber | görev: mevcut görev | çıkış: kapat
parola kelime: bulunan parolayla sonraki seviyeye geç
hardreset: oyun alanını sıfırla ve 1. seviyeye dön (parolalar korunur)
flashback x: daha önce tamamladığın x. seviyeyi baştan aç
gerisar: bulunduğun seviyeyi yeniden başlat (parolalar korunur)

## pwd
Bulunduğun dizinin tam yolunu gösterir. Konum istemde gizlense bile
normalde çalışır; 10. seviyede oyuna özel olarak engellenir.

## ls
Dizin içeriğini listeler: ls veya ls /home/user.
ls -a, noktayla başlayan gizli öğeleri de gösterir.
ls -l: tür/izinler, bağlantı sayısı, sahip, grup, boyut, tarih ve ad.
ls -l dosya.md: yalnızca belirtilen dosyanın ayrıntıları.
Tür ve izin alanı 10 karakterdir; sonraki . veya + bu alana dahil değildir.

## cd
Dizin değiştirir: cd altdizin, cd .., cd ~. Argümansız cd ev dizinine gider.
. mevcut, .. üst dizindir. / ile başlayan yollar mutlaktır; diğerleri
bulunduğun dizine göredir. Boşluk içeren adları tırnakla yaz:
cd "ders notlari". Büyük/küçük harf önemlidir.

## cat
Metin dosyalarını gösterir: cat notlar.md veya cat bir.md iki.md.
Olmayan/okunamayan dosyada hata ve başarısız işlem durumu döndürür.

## mkdir
mkdir yeni: dizin oluşturur. mkdir -p yeni/alt/derin: eksik ara dizinleri
de oluşturur. Oluşturmak, dizinin içine geçmek değildir.

## touch
touch notlar.md: olmayan dosyayı boş olarak oluşturur. Var olan dosyanın
içeriğini silmez; zaman bilgisini günceller.

## cp
cp kaynak.md hedef.md: kopyalar. cp kaynak.md ..: üst dizine aynı adla
kopyalar. Kaynak yerinde kalır. Oyunda temel dosya kopyalama kullanılır.

## mv
mv eski.md yeni.md: yeniden adlandırır. mv belge.md altdizin/: taşır.
Taşınan dosya eski konumunda kalmaz.

## rm
rm gereksiz.md: dosyayı siler. Normalde geri dönüşüm kutusuna gitmez.
Oyunda yalnızca dosya silme kullanılır; . ve .. dizinlerini silmeye çalışma.

## less
less notlar.md: uzun metni kaydırarak gösterir. Yukarı/aşağı oklarla
gezin; q ile çık. Düzenleme yapmaz. Oyunda güvenli modda çalışır.

## find
Dizin ağacını, alt dizinler dahil arar:
find . -name "notlar.md"
find . -name "*deniz*"
find . -type f
-name adı, -type f normal dosyaları seçer. Başlangıç noktası . veya
mutlak bir dizin yolu olabilir. Deseni tırnak içine alarak * işaretini
kabuk yerine find komutunun değerlendirmesini sağlarsın.

## grep
grep "kelime" notlar.md: eşleşen satırları gösterir; büyük/küçük harfe
duyarlıdır. Borudan gelen metni de filtreler. Dosya adını filtrelemek
ile dosya içeriğini aramak farklı işlemlerdir.

## echo
echo "Merhaba": metni yazar. Tek kelimede tırnak zorunlu değildir.
echo Merhaba ile echo "Merhaba" eşdeğerdir. Oyunda değişken genişletme
gibi ileri kabuk özellikleri kullanılmaz.

## nano
nano notlar.md: metin düzenleyici. Ctrl+O ile kaydet, Enter ile dosya
adını onayla, Ctrl+X ile çık. Oyunda kısıtlı mod kullanılır; dosyayı
önce oluşturman gerekir. Başka program veya dosya açılması kısıtlıdır.

## man
man sudo: yardım sayfasını gösterir; q ile çık. Oyunda sabit eğitim
metinleri kullanılır. man -k "dosya": yardım başlıkları/açıklamalarında
anahtar kelime arar; tam sayfada metin aramakla aynı şey değildir.

## Operatörler
| : Soldaki standart çıktıyı sağdaki komuta taşır: ls | grep "not".
> : Dosyaya yazar; var olan içeriğin ÜZERİNE yazar:
echo "Merhaba" > selam.md
>> : Önceki içeriği koruyarak SONA ekler:
echo "Yeni satır" >> selam.md
&& : İlk işlem başarılıysa ikinciyi çalıştırır: cd notlar && ls.
|| : İlk işlem başarısızsa ikinciyi çalıştırır:
cat eksik.md || echo "Okunamadı"
* : Sıfır veya daha fazla karakterle eşleşir: ls not*.
Tırnak içindeki veya kaçışla yazılan yıldız düz karakterdir:
ls "not*" desen aramaz; find . -name "not*" ise deseni find'a verir.
Normal * deseni gizli dosyaları kapsamaz; ls -a ile görebilirsin.
Operatörleri tırnak dışında yaz; echo "a | b" yalnızca metin yazar.
Boru standart hata mesajlarını taşımaz; || mesajından önce ilk komutun
hata mesajını da görebilirsin.

## sudo
Gerçek sistemde başka bir kullanıcı (çoğunlukla yönetici) olarak komut
çalıştırır; yetkilendirme gerekebilir. Oyunda yalnızca apt simülasyonu
için kabul edilir ve yönetici parolası sorulmaz.

## apt
Debian ve türevlerinde paket yönetimi:
sudo apt install paket1 paket2 : kurar
sudo apt remove paket1 : kaldırır
sudo apt list : paketleri listeler
sudo apt update : depolardan güncel paket bilgilerini getirir
sudo apt upgrade : kurulu paketlerin kullanılabilir güncellemelerini yükler
update tek başına programları güncellemez. Oyunda tümü simülasyondur;
gerçek sisteme paket kurulmaz, kaldırılmaz veya güncelleme uygulanmaz.

## chmod
İzinleri değiştirir: chmod +x betik, chmod -x betik.
ls -l örneği: -rwxr--rw-. İlk karakter türdür: - dosya, d dizin.
Sonraki üçlüler sırasıyla sahip, grup, diğerleri içindir.
r: okuma | w: yazma | x: çalıştırma | -: izin yok.
Dizinde r adları listeleme, w girdileri değiştirme, x dizine geçiştir;
bir işlem birden fazla izin gerektirebilir.
Sayısal değerler r=4, w=2, x=1; her üçlüde toplanır:
rwx=7, r-x=5, r--=4, -wx=3, --x=1, rw-=6.
chmod 531 dosya örnektir: sahip r-x, grup -wx, diğerleri --x.
Göreve göre herhangi bir üç basamaklı izin değeri kullanılabilir.
Dosya türü karakteri sayısal izin hesabına katılmaz.

## chown
chown eyub bir.md iki.md uc.md: sahipliği değiştirir.
Gerçek sistemde başka kullanıcıya devir normalde yönetici yetkisi ister.
Oyunda simülasyondur: gerçek dosya sahibi değişmez, yetki/parola istenmez.

## Oyun kuralları
Parolalar normalde beş harfli Türkçe kelimelerdir. Tür/izin alanı ve
yardım metnindeki kelime kullanılan seviyeler istisnadır.
14–15. seviyelerde alternatif dosya değiştirme girişimleri o seviyeyi
başa döndürür; okuma, listeleme ve yardım inceleme cezalandırılmaz.
18. seviyede yanlış geçiş yöntemi reddedilir. Tırnak/boşluk farklılıkları
önemli değildir; gerekli işlem ve operatörler önemlidir.
Oyunu yeniden açınca kaldığın seviye baştan kurulur. hardreset ise
ilerlemeyi 1. seviyeye alır ve mevcut oyun alanını yeniden kurar.
Tamamlanan seviyeler kaydedilir; flashback ile yeniden oynanabilir.
flashback ve gerisar mevcut seviyenin yarım kalan dosya işlemlerini siler.
hardreset, tamamlanan seviyelerin kaydını da temizler.
LINUX101_HELP
}

# Hiçbir kullanıcı girdisi eval, source veya bash -c ile çalıştırılmaz.
tokenize() {
    TOKENS=()
    local text=$1 word='' quote='' active=0 c next i
    [[ $text != *"$OP"* && $text != *"$QSTAR"* ]] || { fail 'Desteklenmeyen kontrol karakteri.'; return 1; }
    for ((i=0; i<${#text}; i++)); do
        c=${text:i:1}
        if [[ $quote == "'" ]]; then
            if [[ $c == "'" ]]; then quote=''
            elif [[ $c == '*' ]]; then word+=$QSTAR
            else word+=$c; fi
        elif [[ $quote == '"' ]]; then
            if [[ $c == '"' ]]; then
                quote=''
            elif [[ $c == '\' && ( ${text:i+1:1} == '"' || ${text:i+1:1} == '\' ) ]]; then
                ((i+=1)); word+=${text:i:1}
            elif [[ $c == '*' ]]; then word+=$QSTAR
            else word+=$c
            fi
        else
            case "$c" in
                "'"|'"') quote=$c; active=1 ;;
                '\')
                    ((i+=1))
                    ((i<${#text})) || { fail 'Eksik kaçış karakteri.'; return 1; }
                    if [[ ${text:i:1} == '*' ]]; then word+=$QSTAR
                    else word+=${text:i:1}; fi
                    active=1 ;;
                ' '|$'\t')
                    if ((active)); then TOKENS+=("$word"); word=''; active=0; fi ;;
                '|'|'&'|'>')
                    if ((active)); then TOKENS+=("$word"); word=''; active=0; fi
                    next=${text:i+1:1}
                    if [[ $next == "$c" ]]; then TOKENS+=("$OP$c$c"); ((i+=1))
                    elif [[ $c == '&' ]]; then fail 'Tek & desteklenmiyor.'; return 1
                    else TOKENS+=("$OP$c")
                    fi ;;
                ';'|'<'|'`') fail 'Bu işaret eğitim komutları arasında değil.'; return 1 ;;
                *) word+=$c; active=1 ;;
            esac
        fi
    done
    [[ -z $quote ]] || { fail 'Kapanmamış tırnak.'; return 1; }
    if ((active)); then TOKENS+=("$word"); fi
}

# Tüm satır çalıştırılmadan önce denetlenir; eksik sağ tarafın önündeki
# komutun dosya/dizinleri değiştirmesine izin verilmez.
validate_tokens() {
    local need_command=1 redirected=0 token i
    for ((i=0; i<${#TOKENS[@]}; i++)); do
        token=${TOKENS[i]}
        case "$token" in
            "$OP|"|"$OP&&"|"$OP||")
                ((need_command == 0)) || { fail 'Eksik komut.'; return 1; }
                [[ $token != "$OP|" || $redirected == 0 ]] || { fail 'Yönlendirme borudan sonra olmalı.'; return 1; }
                need_command=1; redirected=0 ;;
            "$OP>"|"$OP>>")
                ((need_command == 0 && redirected == 0)) || { fail 'Geçersiz yönlendirme.'; return 1; }
                ((i+1<${#TOKENS[@]})) || { fail 'Eksik yönlendirme hedefi.'; return 1; }
                [[ -n ${TOKENS[i+1]} && ${TOKENS[i+1]} != "$OP"* ]] || { fail 'Eksik yönlendirme hedefi.'; return 1; }
                ((i+=1)); redirected=1 ;;
            *)
                ((redirected == 0)) || { fail 'Yönlendirme komutun sonunda olmalı.'; return 1; }
                need_command=0 ;;
        esac
    done
    ((need_command == 0)) || { fail 'Eksik komut.'; return 1; }
}

virtual_path() {
    local p=$1
    if [[ $p == "$ROOT" ]]; then printf '/'
    else printf '%s' "${p#"$ROOT"}"
    fi
}

strip_paths() {
    local line
    while IFS= read -r line || [[ -n $line ]]; do
        printf '%s\n' "${line//"$ROOT"/}"
    done
}

# Mutlak eğitim yollarını fiziksel oyun alanına çevirir; .. ve sembolik
# bağlantılar dâhil alan dışına çıkan bütün yolları reddeder.
resolve() {
    local p=${1-} resolved
    [[ -n $p ]] || { fail 'Dosya veya dizin adı boş olamaz.'; return 1; }
    p=${p//$QSTAR/*}
    case "$p" in
        '~') p="$HOME_GAME" ;;
        '~/'*) p="$HOME_GAME/${p:2}" ;;
        /*) p="$ROOT$p" ;;
        *) p="$CWD/$p" ;;
    esac
    resolved=$(realpath -m -- "$p") || return 1
    [[ $resolved == "$ROOT" || $resolved == "$ROOT/"* ]] || {
        fail 'Oyun alanı dışına çıkamazsın.'; return 1;
    }
    printf '%s' "$resolved"
}

# * sadece dosya işlemlerinin yol argümanlarında genişletilir.
# find ve grep desenleri olduğu gibi kendi komutlarına gider.
expand_paths() {
    PATH_ARGS=()
    local arg p match
    local -a matches
    for arg in "$@"; do
        p=$(resolve "$arg") || return 1
        if [[ $arg == *'*'* ]]; then
            # Kısmen tırnaklı desenlerde yalnızca tırnak dışındaki yıldız
            # genişler; [*] compgen için düz yıldız karakteridir.
            p=$(resolve "${arg//$QSTAR/[*]}") || return 1
            mapfile -t matches < <(compgen -G "$p")
            ((${#matches[@]})) || { fail "Eşleşme yok: $arg"; return 1; }
            for match in "${matches[@]}"; do
                p=$(realpath -m -- "$match")
                [[ $p == "$ROOT/"* ]] || return 1
                PATH_ARGS+=("$p")
            done
        else PATH_ARGS+=("$p")
        fi
    done
}

auth_manual() {
    cat <<'EOF'
SUDO(8)                     Eğitim yardım sayfası                     SUDO(8)

NAME
    sudo - bir komutu başka bir kullanıcı olarak çalıştırır

SYNOPSIS
    sudo command

DESCRIPTION
    Gerçek sistemde sudo yetkilendirme politikasını denetler.
    authentication checks normally precede privileged commands.
    Bu oyun yönetici yetkisi istemez ve sistem paketlerini değiştirmez.

NOTES
    Bu sabit eğitim metni farklı dağıtımlarda aynı sonucu sağlar.
    Final authentication verification is described here.
EOF
}

manual() {
    local name=$1
    if [[ $name == sudo ]]; then auth_manual
    elif [[ $name == -k ]]; then
        cat <<'MAN_INDEX'
pwd (1) - çalışma dizininin yolunu gösterir
ls (1) - dosya ve dizinleri listeler
cd (1) - çalışma dizinini değiştirir
cat (1) - dosya içeriklerini gösterir
mkdir (1) - dizin oluşturur
touch (1) - boş dosya oluşturur veya zamanını değiştirir
cp (1) - dosya kopyalar
mv (1) - dosya taşır veya yeniden adlandırır
rm (1) - dosya siler
less (1) - metni kaydırarak gösterir
find (1) - dosya ve dizinleri arar
grep (1) - eşleşen satırları gösterir
echo (1) - metin yazar
nano (1) - metin dosyası düzenler
man (1) - komut yardımını gösterir
sudo (8) - başka kullanıcı olarak komut çalıştırır
apt (8) - paket yönetimi yapar
chmod (1) - dosya izinlerini değiştirir
chown (1) - dosya sahipliğini değiştirir
MAN_INDEX
    else
        help_text | awk -v heading="## $name" '
            /^## / { printing=($0 == heading); if (printing) found=1 }
            printing { print }
            END { if (!found) exit 1 }
        ' || { fail "Yardım sayfası bulunamadı: $name"; return 1; }
    fi
}

dispatch() {
    local cmd=${1:-} p destination option='' pattern status mode index
    shift || return 1
    local -a options=()
    case "$cmd" in
        pwd)
            (($# == 0)) || return 1
            if ((LEVEL == 10)); then say 'Bu sefer o kadar kolay değil :)'
            else virtual_path "$CWD"; printf '\n'; fi ;;
        cd)
            (($# <= 1)) || return 1
            if (($# == 0)); then p=$HOME_GAME
            else p=$(resolve "$1") || return 1
            fi
            [[ -d $p ]] || { fail 'Dizin bulunamadı.'; return 1; }
            [[ -x $p ]] || { fail 'Dizine girme iznin yok.'; return 1; }
            CWD=$p
            if ((LEVEL == 8)) && [[ $CWD == "$TARGET" ]]; then
                touch -- "$TARGET/${PASSWORDS[LEVEL-1]}" || return 1
                REVEALED=1
            fi ;;
        ls)
            if [[ ${1:-} == -l || ${1:-} == -a ]]; then options+=("$1"); shift; fi
            for p in "$@"; do [[ $p != -* ]] || { fail 'Yalnızca ls, ls -l ve ls -a destekleniyor.'; return 1; }; done
            if (($#)); then expand_paths "$@" || return 1
            else expand_paths . || return 1; fi
            # Mutlak fiziksel oyun yolları terminale sızmasın.
            command ls --color=never "${options[@]}" -- "${PATH_ARGS[@]}" 2> "$STATE_DIR/error" |
                strip_paths
            status=${PIPESTATUS[0]}
            if ((status)); then strip_paths < "$STATE_DIR/error" >&2; fi
            return "$status" ;;
        cat|less|nano)
            (($# > 0)) || { fail 'Bir dosya adı belirt.'; return 1; }
            expand_paths "$@" || return 1
            for p in "${PATH_ARGS[@]}"; do
                [[ ! -d $p ]] || { fail 'Bir metin dosyası seç.'; return 1; }
            done
            if [[ $cmd == cat ]]; then
                command cat -- "${PATH_ARGS[@]}" 2> "$STATE_DIR/error"
                status=$?
                if ((status)); then say 'cat: Dosya okunamadı.' >&2; fi
                return "$status"
            elif [[ $cmd == less ]]; then
                (($# == 1)) && [[ -f ${PATH_ARGS[0]} ]] || return 1
                if [[ -t 0 && -t 1 ]]; then
                    LESSSECURE=1 LESSHISTFILE=- LESSOPEN='' command less -- "${PATH_ARGS[0]}"
                    status=$?
                else
                    command cat -- "${PATH_ARGS[0]}"; status=$?
                fi
                if ((status == 0 && LEVEL == 10)) && [[ ${PATH_ARGS[0]} == "$TASK_DIR/benioku.txt" ]]; then
                    write_noise "$TASK_DIR/less.txt" 90
                    printf 'Mutfak notu: yahni; aradığın parola: %s\n' "${PASSWORDS[LEVEL-1]}" >> "$TASK_DIR/less.txt"
                    write_noise "$TASK_DIR/less.txt" 60 append
                    REVEALED=1
                    say 'Dosyayı kapattın. less.txt oluşturuldu.'
                fi
                return "$status"
            else
                (($# == 1)) || return 1
                [[ -t 0 ]] || { fail 'nano etkileşimli terminal gerektirir.'; return 1; }
                # Restricted nano: başka dosya açma, shell ve dış yazma kapalı.
                command nano --restricted -- "${PATH_ARGS[0]}"
            fi ;;
        mkdir|touch|cp|mv|rm)
            if [[ $cmd == mkdir && ${1:-} == -p ]]; then options=(-p); shift; fi
            (($#)) || return 1
            for p in "$@"; do [[ $p != -* ]] || { fail 'Bu seçenek eğitim listesinde yok.'; return 1; }; done
            expand_paths "$@" || return 1
            for ((index=0; index<${#PATH_ARGS[@]}; index++)); do
                p=${PATH_ARGS[index]}
                if [[ ( $p == "$ROOT" || $p == "$HOME_GAME" || $HOME_GAME == "$p/"* ) &&
                      ( $cmd == rm || ( $cmd == mv && $index -lt $((${#PATH_ARGS[@]}-1)) ) ) ]]; then
                    fail 'Oyun kökü silinemez veya taşınamaz.'; return 1
                fi
                if [[ $cmd == mv && $index -lt $((${#PATH_ARGS[@]}-1)) &&
                      ( $CWD == "$p" || $CWD == "$p/"* ) ]]; then
                    fail 'Önce taşıyacağın dizinin dışına çık.'; return 1
                fi
            done
            if [[ ( $cmd == cp || $cmd == mv ) && ${#PATH_ARGS[@]} -ge 2 ]]; then
                destination=${PATH_ARGS[${#PATH_ARGS[@]}-1]}
                if [[ -d $destination ]]; then
                    for ((index=0; index<${#PATH_ARGS[@]}-1; index++)); do
                        p=$(realpath -m -- "$destination/$(basename -- "${PATH_ARGS[index]}")") || return 1
                        [[ $p == "$ROOT/"* ]] || { fail 'Hedef dosya oyun alanı dışına çıkıyor.'; return 1; }
                    done
                fi
            fi
            command "$cmd" "${options[@]}" -- "${PATH_ARGS[@]}" 2> "$STATE_DIR/error"
            status=$?
            if [[ $status == 0 && $cmd == rm && $LEVEL == 7 && ! -e $TARGET ]]; then
                for p in "${PATH_ARGS[@]}"; do
                    if [[ $p == "$TARGET" ]]; then TARGET_DELETED=1; fi
                done
            fi
            ((status == 0)) || fail "$cmd işlemi tamamlanamadı; yolları ve izinleri kontrol et."
            return "$status" ;;
        find)
            (($# == 3)) || { fail 'Kullanım: find . -name "desen" veya find . -type f'; return 1; }
            p=$(resolve "$1") || return 1
            [[ -d $p ]] || return 1
            option=$2; pattern=${3//$QSTAR/*}
            [[ $option == -name || ( $option == -type && $pattern == f ) ]] || return 1
            if [[ $1 == . ]]; then
                (cd -- "$CWD" && command find . "$option" "$pattern")
            else
                command find "$p" "$option" "$pattern" | strip_paths
                return "${PIPESTATUS[0]}"
            fi ;;
        grep)
            (($# >= 1)) || return 1
            pattern=${1//$QSTAR/*}; shift
            if (($#)); then
                expand_paths "$@" || return 1
                command grep -- "$pattern" "${PATH_ARGS[@]}" 2> "$STATE_DIR/error" | strip_paths
                status=${PIPESTATUS[0]}
                if ((status > 1)); then strip_paths < "$STATE_DIR/error" >&2; fi
                return "$status"
            else command grep -- "$pattern" < "$INPUT"
            fi ;;
        echo) p=$*; printf '%s\n' "${p//$QSTAR/*}" ;;
        man)
            if [[ ${1:-} == -k && $# == 2 ]]; then manual -k | command grep -i -- "$2"
            elif (($# == 1)); then
                if [[ -t 1 && -t 0 ]]; then manual "$1" | LESSSECURE=1 LESSHISTFILE=- command less
                else manual "$1"; fi
            else return 1; fi ;;
        chmod)
            (($# >= 2)) || return 1
            mode=$1; shift
            [[ $mode == +x || $mode == -x || $mode =~ ^[0-7]{3}$ ]] || { fail 'Üç basamaklı izin, +x veya -x kullan.'; return 1; }
            expand_paths "$@" || return 1
            command chmod -- "$mode" "${PATH_ARGS[@]}" ;;
        chown)
            (($# >= 2)) && [[ $1 == eyub ]] || { fail 'Bu oyunda sahiplik hedefi eyub.'; return 1; }
            shift
            expand_paths "$@" || return 1
            for p in "${PATH_ARGS[@]}"; do [[ -f $p ]] || return 1; done
            for p in "${PATH_ARGS[@]}"; do printf '%s\n' "$p" >> "$STATE_DIR/owners"; done
            say 'Sahiplik oyun içinde eyub kullanıcısına devredildi.' ;;
        sudo)
            [[ ${1:-} == apt ]] || { fail 'Yalnızca eğitimdeki apt işlemleri simüle edilir.'; return 1; }
            shift
            case "${1:-}" in
                install|remove) (($# >= 2)) || return 1 ;;
                list|update|upgrade) (($# == 1)) || return 1 ;;
                *) return 1 ;;
            esac
            say "[Simülasyon] apt $* başarılı. Gerçek sistem değiştirilmedi." ;;
        *) fail "Bu komut oyunda desteklenmiyor: $cmd. Rehber için yardım yaz."; return 1 ;;
    esac
}

dispatch_stage() {
    # Bash'teki gibi borudaki cd vb. ana çalışma dizinini değiştirmez.
    if ((PIPE_SUBSHELL)); then (dispatch "$@")
    else dispatch "$@"; fi
}

# Sözdizimi: pipeline -> yönlendirme; && ve || soldan sağa kısa devre.
run_pipeline() {
    local -a words=("$@") part=()
    local out='' operator='' token i=0 stage=0 result=0 previous=/dev/null
    local capture="$STATE_DIR/pipe.$BASHPID"
    local PIPE_SUBSHELL=0
    for token in "${words[@]}"; do [[ $token != "$OP|" ]] || PIPE_SUBSHELL=1; done
    for ((i=0; i<${#words[@]}; i++)); do
        token=${words[i]}
        if [[ $token == "$OP>" || $token == "$OP>>" ]]; then
            [[ -z $out && $((i+2)) -eq ${#words[@]} ]] || { fail 'Yönlendirme satırın sonunda olmalı.'; return 1; }
            operator=${token#"$OP"}
            out=$(resolve "${words[i+1]}") || return 1
            [[ $out != "$ROOT" && $out != "$HOME_GAME" ]] || return 1
            break
        fi
    done
    if [[ -n $out ]]; then words=("${words[@]:0:i}"); fi
    for ((i=0; i<=${#words[@]}; i++)); do
        if ((i == ${#words[@]})); then token="$OP|"; else token=${words[i]}; fi
        if [[ $token == "$OP|" ]]; then
            ((${#part[@]})) || { fail 'Eksik boru komutu.'; return 1; }
            INPUT=$previous
            if ((i < ${#words[@]})); then
                dispatch_stage "${part[@]}" > "$capture.$stage"
                result=$?; previous="$capture.$stage"; ((stage+=1))
            elif [[ $operator == '>' ]]; then
                dispatch_stage "${part[@]}" > "$out"; result=$?
            elif [[ $operator == '>>' ]]; then
                dispatch_stage "${part[@]}" >> "$out"; result=$?
            else
                # Yalnızca terminale gönderilen son aşama çıktısını kaydet.
                # Etkileşimli programların gerçek TTY bağlantısını koru.
                if ((LEVEL == 16)) && [[ ${part[0]} != nano && ${part[0]} != less && ${part[0]} != man ]]; then
                    dispatch_stage "${part[@]}" > "$STATE_DIR/stdout-stage"
                    result=$?
                    cat "$STATE_DIR/stdout-stage" >> "$STATE_DIR/terminal-output"
                    cat "$STATE_DIR/stdout-stage"
                else dispatch_stage "${part[@]}"; result=$?
                fi
            fi
            part=()
        else part+=("$token")
        fi
    done
    INPUT=/dev/null
    for ((i=0; i<stage; i++)); do command rm -f -- "$capture.$i"; done
    return "$result"
}

run_tokens() {
    local -a part=()
    local token condition='' result=0 i
    for ((i=0; i<=${#TOKENS[@]}; i++)); do
        if ((i == ${#TOKENS[@]})); then token="$OP&&"; else token=${TOKENS[i]}; fi
        if [[ $token == "$OP&&" || $token == "$OP||" ]]; then
            ((${#part[@]})) || { fail 'Eksik koşullu komut.'; return 1; }
            if [[ -z $condition || ( $condition == '&&' && $result == 0 ) || ( $condition == '||' && $result != 0 ) ]]; then
                run_pipeline "${part[@]}"; result=$?
            fi
            condition=${token#"$OP"}; part=()
        else part+=("$token")
        fi
    done
    return "$result"
}

matches() {
    local -a expected=("$@")
    local i
    ((${#TOKENS[@]} == ${#expected[@]})) || return 1
    for ((i=0; i<${#expected[@]}; i++)); do
        case "${expected[i]}" in
            '|'|'&&'|'||'|'>'|'>>') expected[i]="$OP${expected[i]}" ;;
        esac
        [[ ${TOKENS[i]//$QSTAR/*} == "${expected[i]}" ]] || return 1
    done
}

random_name() {
    local n
    n=$(od -An -N8 -tx1 /dev/urandom | tr '0123456789' 'ghijklmnop')
    n=${n//[[:space:]]/}
    printf 'd%s' "${n:0:8}"
}
make_random_dir() {
    local p="$1/$(random_name)"
    while [[ -e $p ]]; do p="$1/$(random_name)"; done
    mkdir -- "$p" || return 1
    printf '%s' "$p"
}
write_noise() {
    local file=$1 count=$2 i
    [[ ${3:-} == append ]] || : > "$file"
    for ((i=1; i<=count; i++)); do printf 'Not %03d: Bu satır günlük çalışma kaydıdır.\n' "$i" >> "$file"; done
}

decoy_files() {
    local directory=$1 count=$2 extension=${3:-md} i
    for ((i=1; i<=count; i++)); do
        printf 'Bu dosya bir alıştırma kaydıdır; hedef dosya değildir.\n' > "$directory/kayit_${i}.$extension"
    done
}

setup_level() {
    # Yalnızca uygulamanın oluşturduğu ve işaretlediği alan yenilenir.
    [[ -f "$STATE_DIR/.linux101-state" ]] || { fail 'Oyun alanı işareti eksik.'; return 1; }
    ROOT="$STATE_DIR/world"
    # Oyuncu chmod ile dizin erişimini kaldırmış olabilir. find sembolik
    # bağlantıları takip etmeden, inişten önce her dizini erişilebilir yapar.
    if [[ -d $ROOT && ! -L $ROOT ]]; then
        chmod u+rwx -- "$ROOT" || { DONE=1; fail 'Oyun alanı erişimi düzeltilemedi.'; return 1; }
        find "$ROOT" -type d -exec chmod u+rwx -- '{}' ';' || { DONE=1; fail 'Dizin izinleri düzeltilemedi.'; return 1; }
    fi
    command rm -rf -- "$ROOT" || { DONE=1; fail 'Eski oyun alanı temizlenemedi.'; return 1; }
    command mkdir -p -- "$ROOT/home/user" || { DONE=1; fail 'Oyun alanı oluşturulamadı.'; return 1; }
    HOME_GAME="$ROOT/home/user"
    CWD="$HOME_GAME"
    TARGET=''
    REVEALED=0
    TARGET_DELETED=0
    : > "$STATE_DIR/owners"
    local pass=${PASSWORDS[LEVEL-1]} i j p q d leaf index=0
    local -a branches next
    case "$LEVEL" in
        1)
            mkdir -p "$HOME_GAME/Welcome"; CWD="$HOME_GAME/Welcome"
            touch "$HOME_GAME/$pass"; mkdir "$HOME_GAME/Belgeler"
            decoy_files "$HOME_GAME" 12 txt
            for ((i=1; i<=8; i++)); do mkdir "$HOME_GAME/arsiv_$i"; done ;;
        2) mkdir "$HOME_GAME/directory_1"; printf '%s\n' "$pass" > "$HOME_GAME/directory_1/parola.txt" ;;
        3) touch "$HOME_GAME/borg.md"; chmod 716 "$HOME_GAME/borg.md" ;;
        4)
            mkdir -p "$HOME_GAME/izler/baslangic" "$HOME_GAME/hello_friend"
            CWD="$HOME_GAME/izler/baslangic"
            say 'Aradığın parola, /home/user/hello_friend/kerman.txt dosyasının içinde yazıyor.' > "$HOME_GAME/izler/yonlendirme.txt"
            say "$pass" > "$HOME_GAME/hello_friend/kerman.txt" ;;
        5) mkdir "$HOME_GAME/gazisiber" ;;
        6)
            mkdir -p "$HOME_GAME/anadizin/altdizin"; CWD="$HOME_GAME/anadizin"
            say 'GNU/Linux dosya kopyalama alıştırması.' > "$CWD/benikopyala.md"
            cp "$CWD/benikopyala.md" "$STATE_DIR/copy-original" ;;
        7)
            mkdir "$HOME_GAME/gizli"; CWD="$HOME_GAME/gizli"
            say 'Silinecek gizli dosya.' > "$CWD/.sakli.md"
            decoy_files "$CWD" 30
            for ((i=1; i<=12; i++)); do mkdir "$CWD/arsiv_$i"; done
            TARGET="$CWD/.sakli.md" ;;
        8)
            mkdir -p "$HOME_GAME/orman/oda"; CWD="$HOME_GAME/orman/oda"
            TARGET="$CWD/orman/dididizin" ;;
        9)
            mkdir -p "$HOME_GAME/dizin/$(random_name)/$(random_name)"
            CWD="$HOME_GAME/dizin"
            leaf=$(find "$CWD" -mindepth 2 -maxdepth 2 -type d)
            TARGET="$leaf/benitasi.md"
            say 'Taşıma görevi: bu dosyayı deniz.md dosyasının yanına taşı.' > "$CWD/benitasi.md"
            cp "$CWD/benitasi.md" "$STATE_DIR/move-original"
            say 'Hedef dizin burası.' > "$leaf/deniz.md"
            for ((i=1; i<=40; i++)); do
                p=$(make_random_dir "$CWD"); q=$(make_random_dir "$p")
                decoy_files "$q" 4
            done ;;
        10)
            mkdir -p "$HOME_GAME/$(random_name)/$(random_name)"
            CWD=$(find "$HOME_GAME" -mindepth 2 -maxdepth 2 -type d)
            write_noise "$CWD/benioku.txt" 100 ;;
        11)
            branches=("$HOME_GAME")
            for ((i=1; i<=5; i++)); do
                next=()
                for p in "${branches[@]}"; do
                    for ((j=1; j<=3; j++)); do
                        if ((i == 3 && index == 0 && j == 1)); then
                            q="$p/topcuoglu"; mkdir "$q"
                        else q=$(make_random_dir "$p")
                        fi
                        next+=("$q")
                        decoy_files "$q" 2
                    done
                    ((index+=1))
                done
                # index üçüncü derinlikte ilk topcuoglu dalını seçmek için sıfırlanır.
                branches=("${next[@]}"); index=0
            done
            TARGET=$(find "$HOME_GAME" -type d -name topcuoglu)
            say "$pass" > "$TARGET/deniz.md"
            for p in "${branches[@]}"; do say 'Bu dosyada aradığın parola yok.' > "$p/deniz.md"; done ;;
        12)
            mkdir "$HOME_GAME/samanlik"; CWD="$HOME_GAME/samanlik"
            mkdir "$CWD/sdjedipsa"
            say "$pass" > "$CWD/sdjedipsa/jjddenizq.txt"
            decoy_files "$CWD/sdjedipsa" 4 txt
            for ((i=1; i<=499; i++)); do
                p=$(make_random_dir "$CWD")
                decoy_files "$p" 5 txt
                if ((i % 5 == 0)); then say 'Yanlış dizin: burada parola yok.' > "$p/deniz_notlari.txt"; fi
            done ;;
        13)
            mkdir "$HOME_GAME/arama"; CWD="$HOME_GAME/arama"
            for ((i=1; i<=500; i++)); do
                p=$(make_random_dir "$CWD")
                if ((i == 237)); then
                    write_noise "$p/merhaba.md" 80
                    printf 'gazisiber eğitim parolası: %s\n' "$pass" >> "$p/merhaba.md"
                    write_noise "$p/merhaba.md" 70 append
                else
                    q=$(make_random_dir "$p")
                    decoy_files "$q" 3
                fi
            done ;;
        14)
            mkdir "$HOME_GAME/yonlendirme"; CWD="$HOME_GAME/yonlendirme"
            # Tam 10.000 ASCII karakter: 100 satır, satır sonları dâhil.
            for ((i=0; i<100; i++)); do
                p=$(od -An -N64 -tx1 /dev/urandom); p=${p//[[:space:]]/}
                printf '%s\n' "${p:0:99}"
            done > "$CWD/looong.md" ;;
        15)
            mkdir -p "$HOME_GAME/boom" "$HOME_GAME/liste"; CWD="$HOME_GAME/liste"
            say '# Önceden kaydedilmiş yollar — bu satırı koru.' > "$CWD/path.md"
            cp "$CWD/path.md" "$STATE_DIR/path-original"
            for ((i=0; i<60; i++)); do
                p="$HOME_GAME/boom/$(random_name)/$(random_name)"; mkdir -p "$p"
                if ((i % 2 == 0)); then touch "$p/yunus.md"; else touch "$p/diger.md"; fi
                decoy_files "$p" 3
            done ;;
        16)
            mkdir "$HOME_GAME/listeleme"; CWD="$HOME_GAME/listeleme"
            touch "$HOME_GAME/murat_systemd.md" "$HOME_GAME/murat_systemd_notlari.md" "$HOME_GAME/murat_ag.md" "$HOME_GAME/baska_systemd.md"
            for ((i=1; i<=40; i++)); do
                touch "$HOME_GAME/murat_not_$i.md" "$HOME_GAME/arsiv_murat_$i.md" "$HOME_GAME/diger_not_$i.md"
            done ;;
        17) mkdir "$HOME_GAME/kosul"; CWD="$HOME_GAME/kosul" ;;
        18) mkdir "$HOME_GAME/zincir"; CWD="$HOME_GAME/zincir" ;;
        19|20) mkdir "$HOME_GAME/paketler"; CWD="$HOME_GAME/paketler" ;;
        21)
            mkdir "$HOME_GAME/izinler"; CWD="$HOME_GAME/izinler"
            touch "$CWD/baslat.md" "$CWD/notlar.md" "$CWD/oku.md"
            decoy_files "$CWD" 40
            chmod 644 "$CWD/"*.md; chmod +x "$CWD/baslat.md"
            TARGET="$CWD/baslat.md" ;;
        22)
            mkdir "$HOME_GAME/sahiplik"; CWD="$HOME_GAME/sahiplik"
            touch "$CWD/bir.md" "$CWD/iki.md" "$CWD/uc.md" ;;
        23)
            mkdir "$HOME_GAME/izinler"; CWD="$HOME_GAME/izinler"
            touch "$CWD/dosya.c"; chmod 644 "$CWD/dosya.c" ;;
        24) PASSWORDS[23]=verification ;;
        25) PASSWORDS[24]=yahni ;;
    esac
    TASK_DIR=$CWD
    chmod 700 "$STATE_DIR"
    save_level "$LEVEL"
}

save_level() {
    printf '%s\n' "$1" > "$STATE_DIR/level.tmp" &&
        mv -f -- "$STATE_DIR/level.tmp" "$STATE_DIR/level" || {
            DONE=1; fail 'Seviye kaydedilemedi.'; return 1;
        }
}

mark_completed() {
    local -a entries=()
    [[ ! -f "$STATE_DIR/completed" ]] || mapfile -t entries < "$STATE_DIR/completed"
    if grep -Fxq -- "$LEVEL" "$STATE_DIR/completed" 2>/dev/null; then return 0; fi
    printf '%s\n' "${entries[@]}" "$LEVEL" > "$STATE_DIR/completed.tmp" &&
        mv -f -- "$STATE_DIR/completed.tmp" "$STATE_DIR/completed" || {
            DONE=1; fail 'Tamamlanma kaydı yazılamadı.'; return 1;
        }
}

show_task() {
    printf '\n════════════ Seviye %s / 25 ════════════\n' "$LEVEL"
    case "$LEVEL" in
        1) say '~/Welcome dizinindesin. ~ dizinine geç ve içeriğini listele. Parola, listelemede görünecek dosyalardan birinin adıdır.'; say 'Komutlar: cd, ls' ;;
        2) say 'Aradığın parola, /home/user/directory_1/parola.txt dosyasının içeriğinde yazıyor.'; say 'Komut: cat' ;;
        3) say 'Bu seviyeye özel olarak parola, /home/user/borg.md dosyasının izin ayrıntılarındaki ilk 10 karakterlik tür ve izin alanıdır. Sonrasında görülebilen . veya + işaretleri parolaya dahil değildir.'; say 'Komut: ls -l' ;;
        4) say 'Şu anda hangi dizinde olduğunu öğren, ardından bir üst dizine git ve oradaki metin dosyasının içine göz at.'; say 'Komutlar: pwd, cd, ls, cat' ;;
        5) say '/home/user/gazisiber dizininde distro.txt isimli bir dosya oluştur ve nano ile içine debian yaz. Tamamladığında parola terminalde gösterilecek.'; say 'Komutlar: cd, touch, nano' ;;
        6) say 'Bulunduğun dizin içerisinde benikopyala.md isimli bir dosya var. Bu dosyayı bir üst ve hazır bir alt dizine kopyaladığında terminalde parolanı göreceksin.'; say 'Bu seviyeden itibaren komutlar gösterilmez. Rehber için yardım yazabilirsin.' ;;
        7) say 'Bulunduğun dizin içerisinde gizli bir dosya var. O dosyayı sildiğinde parolan terminalde gösterilecek.' ;;
        8) say 'Şu anda bulunduğun dizini senden saklıyoruz. Bu dizinin adını bir şekilde öğren ve bulunduğun dizinin bir üst dizini ile aynı adda bir alt dizin oluştur. O alt dizinin içerisine dididizin adlı bir alt dizin daha oluştur. dididizin dizinine girdiğin an parolan ile aynı isimde bir dosya oluşacak.' ;;
        9) say 'Bulunduğun dizin içerisinde benitasi.md dosyası var. Bu dosyayı deniz.md dosyasının bulunduğu dizine taşıdığında, taşıdığın dosyanın içerisinde parolanı göreceksin.' ;;
        10) say 'Dosyanın içeriğini yukarı ve aşağı ok tuşlarıyla kaydırarak göstermeye yarayan komutu kullanarak benioku.txt dosyasını açıp kapat. Ardından less.txt dosyası oluşacak. Bu dosyada bir yerlerde parolan yazıyor. İpucu: parolanın yazdığı satırda yahni yazıyor.' ;;
        11) say '/home/user dizini altındaki deniz.md isimli dosyalardan birinde aradığın parola yazıyor. Aradığın dosya, topcuoglu isimli bir dizinin altında.' ;;
        12) say 'Bulunduğun dizinde 500 alt dizin var. Aradığın parola, adında edip geçen dizinlerden birinin içinde, adında deniz geçen bir dosyada yazıyor.' ;;
        13) say 'Bulunduğun dizinde 500 alt dizin var. 499 tanesinin altında başka bir dizin, bir tanesinin altında ise merhaba.md var. Parolan bu dosyadaki satırlardan birinde yazıyor. İpucu: parola ile aynı satırda gazisiber yazıyor.' ;;
        14) say 'Bulunduğun dizinde looong.md var. İçeriğindeki tüm metni, oluşturacağın merhaba.md dosyasına yaz. Parola terminalde belirecek. Dosyayı okuyan komut ile çıktıyı dosyaya yönlendiren operatörü birlikte kullanmalısın. Başka yöntem denersen bu seviye başa sarar.' ;;
        15) say '/home/user/boom altındaki tüm yunus.md dosyalarının yollarını bul ve path.md dosyasının sonuna ekle. Mevcut içeriği korumalısın. Arama komutunu ve sona ekleme operatörünü birlikte kullan. Başka yöntem denersen bu seviye başa sarar. Parola terminalde belirecek.' ;;
        16) say 'Bulunduğun dizinin bir üst dizinindeki murat ile başlayan dosya adlarından systemd içerenleri listele. Listeleme çıktısını filtreleyen komuta aktar. Çıktıda yalnızca aranan iki dosyanın tam yolu bulunmalı; doğru işlemde parola terminalde belirecek.' ;;
        17) say 'Öyle bir komut gir ki, bulunduğun dizinde aslında var olmayan benvarim.md dosyasını okuyamayınca terminale Basaramadik yazsın. Bu sorunun cevabını terminale girmen yeterli.' ;;
        18) say 'Önce bulunduğun dizinde artikvarim isimli bir dizin oluştur. Ardından tek satır komutla, dizine geçiş başarılı olduğunda içeriğini listele. Otomatik oluşacak dosyanın adı paroladır. İkinci işlemi yanlış yöntemle yaparsan girdi reddedilir.' ;;
        19) say 'cowsay ve btop isimli paketleri Debian’ın kullandığı paket yöneticisiyle tek satır komutla nasıl yükleriz?' ;;
        20) say 'Tek satır komutla önce depolardan güncel paket bilgilerini getir, ardından kurulu paketler için kullanılabilir güncellemeleri yükle.' ;;
        21) say 'Bulunduğun dizin içerisinde çalıştırma yetkin olan dosyayı bul ve çalıştırma iznini kaldır.' ;;
        22) say 'Bulunduğun dizinde sahibi olduğun üç adet dosya var. Üç dosyanın da sahipliğini eyub kullanıcısına devret. Devrettiğinde parola otomatik terminale yazılacak. Yönetici yetkisi veya parolası istenmez.' ;;
        23) say 'Sahibi olduğun dosya.c dosyasının izinlerini rwxr--rw- olacak şekilde düzenle.' ;;
        24) say 'sudo komutunun yardım sayfasında geçen son authentication kelimesinin hemen ardından gelen kelime, aradığın paroladır. Yardım sayfasını eşleşen satırları gösterecek şekilde filtrele. Bu seviyenin parolası Türkçe kelime kuralının istisnasıdır.' ;;
        25) say 'Eğitime katıldığın, buraya kadar geldiğin için teşekkür ederim. Eğer GNU/Linux konusundaki teknik bilgini arttırmak, yeni şeyler öğrenmek ve bu alanda varlık göstermek istiyorsan seni de Özgür Yazılım ve Linux Ekibine bekleriz. Emeğine sağlık. Aradığın parola: yahni.' ;;
    esac
}

reveal() {
    if ((REVEALED == 0)); then
        printf '\nParolan: %s\n' "${PASSWORDS[LEVEL-1]}"
        say 'Geçmek için: parola <bulduğun-parola>'
        REVEALED=1
    fi
}

check_completion() {
    local p mode ok=1
    case "$LEVEL" in
        5)
            p="$HOME_GAME/gazisiber/distro.txt"
            if [[ -f $p ]] && [[ $(cat "$p") == debian ]]; then reveal; fi ;;
        6)
            if cmp -s "$STATE_DIR/copy-original" "$HOME_GAME/benikopyala.md" &&
               cmp -s "$STATE_DIR/copy-original" "$HOME_GAME/anadizin/altdizin/benikopyala.md" &&
               cmp -s "$STATE_DIR/copy-original" "$HOME_GAME/anadizin/benikopyala.md"; then reveal; fi ;;
        7) if ((TARGET_DELETED)) && [[ ! -e $TARGET ]]; then reveal; fi ;;
        9)
            if [[ ! -e "$HOME_GAME/dizin/benitasi.md" ]] && cmp -s "$STATE_DIR/move-original" "$TARGET"; then
                say "${PASSWORDS[LEVEL-1]}" > "$TARGET"
                say 'Dosya doğru yere taşındı. İçeriğine göz at.'
            fi ;;
        14)
            if [[ $CWD == "$TASK_DIR" ]] && matches cat looong.md '>' merhaba.md && cmp -s "$TASK_DIR/looong.md" "$TASK_DIR/merhaba.md"; then reveal; fi ;;
        15)
            if [[ $CWD == "$TASK_DIR" ]] && matches find /home/user/boom -name yunus.md '>>' path.md; then
                { cat "$STATE_DIR/path-original"; find "$HOME_GAME/boom" -name yunus.md | strip_paths; } > "$STATE_DIR/path-expected"
                if cmp -s "$TASK_DIR/path.md" "$STATE_DIR/path-expected"; then reveal; fi
            fi ;;
        16)
            if [[ $(wc -l < "$STATE_DIR/terminal-output") -eq 2 ]] &&
               grep -Fxq '/home/user/murat_systemd.md' "$STATE_DIR/terminal-output" &&
               grep -Fxq '/home/user/murat_systemd_notlari.md' "$STATE_DIR/terminal-output"; then reveal; fi ;;
        17) if matches cat benvarim.md '||' echo Basaramadik && [[ ! -e "$CWD/benvarim.md" ]]; then reveal; fi ;;
        18)
            if matches cd artikvarim '&&' ls && [[ $CWD == "$HOME_GAME/zincir/artikvarim" ]]; then REVEALED=1; fi ;;
        19) if matches sudo apt install cowsay btop || matches sudo apt install btop cowsay; then reveal; fi ;;
        20) if matches sudo apt update '&&' sudo apt upgrade; then reveal; fi ;;
        21)
            if [[ -f $TARGET ]]; then
                mode=$(stat -c %a "$TARGET")
                if (( (8#$mode & 0111) == 0 )); then reveal; fi
            fi ;;
        22)
            for p in bir.md iki.md uc.md; do
                grep -Fxq -- "$HOME_GAME/sahiplik/$p" "$STATE_DIR/owners" || ok=0
            done
            if ((ok)); then reveal; fi ;;
        23) if [[ $(stat -c %a "$HOME_GAME/izinler/dosya.c" 2>/dev/null) == 746 ]]; then reveal; fi ;;
    esac
}

guard_method() {
    local token risky=0 command_position=1 has_cd=0
    if ((LEVEL == 14 || LEVEL == 15)); then
        if ((LEVEL == 14)) && matches cat looong.md '>' merhaba.md; then return 0; fi
        if ((LEVEL == 15)) && matches find /home/user/boom -name yunus.md '>>' path.md; then return 0; fi
        for token in "${TOKENS[@]}"; do
            case "$token" in
                "$OP>"|"$OP>>") risky=1 ;;
                "$OP|"|"$OP&&"|"$OP||") command_position=1 ;;
                *)
                    if ((command_position)); then
                        case "$token" in cp|mv|rm|touch|mkdir|nano|chmod|chown) risky=1 ;; esac
                        command_position=0
                    fi ;;
            esac
        done
        if ((risky)); then
            say 'Yanlış çözüm yöntemi. Yalnızca bu seviye başlangıca döndü.'
            setup_level || return 1
            show_task; return 1
        fi
    elif ((LEVEL == 18)); then
        for token in "${TOKENS[@]}"; do
            case "$token" in
                "$OP|"|"$OP&&"|"$OP||") command_position=1 ;;
                *)
                    if ((command_position)); then
                        [[ $token != cd ]] || has_cd=1
                        command_position=0
                    fi ;;
            esac
        done
        if ((has_cd)); then
            matches cd artikvarim '&&' ls || { fail 'Dizine geçişi ve listelemeyi başarı koşuluyla birleştirmelisin.'; return 1; }
        fi
        if matches cd artikvarim '&&' ls; then
            [[ $CWD == "$TASK_DIR" && -d "$TASK_DIR/artikvarim" ]] || { fail 'Önce başlangıç dizininde artikvarim dizinini oluştur.'; return 1; }
            [[ -x "$TASK_DIR/artikvarim" ]] || { fail 'Dizine girme iznin yok.'; return 1; }
            touch "$TASK_DIR/artikvarim/${PASSWORDS[LEVEL-1]}" || return 1
        fi
    fi
}

attempt_password() {
    ((${#TOKENS[@]} == 2)) || { say 'Kullanım: parola <bulduğun-parola>'; return; }
    if [[ ${TOKENS[1]} != "${PASSWORDS[LEVEL-1]}" ]]; then say 'Parola yanlış. Tekrar dene.'; return; fi
    case "$LEVEL" in
        5|6|7|14|15|16|17|18|19|20|21|22|23)
            ((REVEALED)) || { say 'Önce bu seviyenin görevini tamamlamalısın.'; return; } ;;
        8) ((REVEALED)) && [[ -f "$TARGET/${PASSWORDS[LEVEL-1]}" ]] || { say 'Önce doğru dididizin dizinine girmelisin.'; return; } ;;
        9) [[ -f $TARGET ]] && [[ $(cat "$TARGET") == "${PASSWORDS[LEVEL-1]}" ]] || { say 'Önce taşıma görevini tamamlamalısın.'; return; } ;;
        10) ((REVEALED)) && [[ -f "$TASK_DIR/less.txt" ]] || { say 'Önce görüntüleme görevini tamamlamalısın.'; return; } ;;
    esac
    mark_completed || return 1
    if ((LEVEL == 25)); then
        save_level 26 || return 1
        DONE=1
        say 'Tebrikler! 25 seviyenin tamamını bitirdin. Özgür yazılımla kal!'
    else
        say 'Doğru parola! Bir sonraki seviyeye geçiyorsun.'
        ((LEVEL+=1)); setup_level || return 1
        show_task
    fi
}

process_line() {
    local line=$1 status
    : > "$STATE_DIR/terminal-output"
    tokenize "$line" || return
    ((${#TOKENS[@]})) || return
    validate_tokens || return
    case "${TOKENS[0]}" in
        hardreset)
            ((${#TOKENS[@]} == 1)) || { say 'Kullanım: hardreset'; return; }
            LEVEL=1
            DONE=0
            setup_level || return 1
            : > "$STATE_DIR/completed"
            say 'Oyun sıfırlandı. 1. seviyeye döndün.'
            show_task
            return ;;
        flashback)
            if ((${#TOKENS[@]} != 2)) || [[ ! ${TOKENS[1]:-} =~ ^([1-9]|1[0-9]|2[0-5])$ ]]; then
                say 'Kullanım: flashback <1-25>'
                return
            fi
            if [[ ! -f "$STATE_DIR/completed" ]] || ! grep -Fxq -- "${TOKENS[1]}" "$STATE_DIR/completed"; then
                say 'Bu seviyeyi henüz tamamlamadın. flashback yalnızca geçilmiş seviyeleri açar.'
                return
            fi
            LEVEL=${TOKENS[1]}
            DONE=0
            setup_level || return 1
            say "Tamamladığın $LEVEL. seviyeye döndün."
            show_task
            return ;;
        gerisar)
            ((${#TOKENS[@]} == 1)) || { say 'Kullanım: gerisar'; return; }
            DONE=0
            setup_level || return 1
            say "Seviye $LEVEL yeniden başlatıldı."
            show_task
            return ;;
        denizsays)
            if ((${#TOKENS[@]} != 2)) || [[ ! ${TOKENS[1]:-} =~ ^([1-9]|1[0-9]|2[0-5])$ ]]; then
                say 'Kullanım: denizsays <1-25>'
                return
            fi
            LEVEL=${TOKENS[1]}
            DONE=0
            setup_level || return 1
            show_task
            return ;;
        cikis|çıkış)
            ((${#TOKENS[@]} == 1)) || { say 'Kullanım: çıkış'; return; }
            DONE=1; say 'İlerlemen kaydedildi. Görüşmek üzere!'; return ;;
        gorev|görev)
            ((${#TOKENS[@]} == 1)) || { say 'Kullanım: görev'; return; }
            show_task; return ;;
        yardim|yardım|help)
            ((${#TOKENS[@]} == 1)) || { say 'Kullanım: yardım'; return; }
            if [[ -t 0 && -t 1 ]]; then help_text | LESSSECURE=1 LESSHISTFILE=- command less
            else help_text; fi
            return ;;
        parola) attempt_password; return ;;
    esac
    guard_method || return
    run_tokens; status=$?
    if ((status == 0)); then check_completion; fi
}

init_state() {
    local fresh=$1
    mkdir -p -- "$STATE_DIR" || { fail 'Kayıt dizini oluşturulamadı.'; return 1; }
    STATE_DIR=$(realpath -- "$STATE_DIR")
    [[ $STATE_DIR != / && $STATE_DIR != "$SCRIPT_DIR" ]] || { fail 'Geçersiz kayıt dizini.'; return 1; }
    local file value index finished=0
    for file in .linux101-state passwords level completed owners error lock level.tmp completed.tmp copy-original move-original path-original path-expected terminal-output stdout-stage; do
        if [[ -L "$STATE_DIR/$file" || ( -e "$STATE_DIR/$file" && ! -f "$STATE_DIR/$file" ) ]]; then
            fail "Kayıt bozuk: $file normal dosya olmalı."; return 1
        fi
    done
    [[ ! -L "$STATE_DIR/world" ]] || { fail 'Kayıt bozuk: oyun alanı sembolik bağlantı olamaz.'; return 1; }
    if [[ ! -f "$STATE_DIR/.linux101-state" ]]; then
        [[ -z $(find "$STATE_DIR" -mindepth 1 -maxdepth 1 -print -quit) ]] || {
            fail 'Kayıt dizini boş değil ve bu oyuna ait değil.'; return 1;
        }
        touch "$STATE_DIR/.linux101-state"
    fi
    chmod 700 "$STATE_DIR" || return 1
    exec {STATE_LOCK_FD}> "$STATE_DIR/lock" || return 1
    flock -n "$STATE_LOCK_FD" || { fail 'Bu kayıt başka bir oyun oturumunda kullanılıyor.'; return 1; }
    if ((fresh == 0)) && [[ ! -f "$STATE_DIR/passwords" &&
        ( -e "$STATE_DIR/level" || -e "$STATE_DIR/completed" || -e "$STATE_DIR/world" ) ]]; then
        fail 'Kayıt bozuk: parola kaydı eksik; yeni oyun için --new kullan.'; return 1
    fi
    if ((fresh)) || [[ ! -f "$STATE_DIR/passwords" ]]; then
        local -a pool=(yahni deniz kalem kitap kilim limon kiraz biber gazoz kazan tabak sabun hamur saman tohum bulut damla orman yazar masal merak demir bakir ceviz armut)
        mapfile -t PASSWORDS < <(printf '%s\n' "${pool[@]}" | shuf)
        PASSWORDS[2]='-rwx--xrw-'; PASSWORDS[23]=verification; PASSWORDS[24]=yahni
        printf '%s\n' "${PASSWORDS[@]}" > "$STATE_DIR/passwords" || return 1
        : > "$STATE_DIR/completed" || return 1
        LEVEL=1
    else
        mapfile -t PASSWORDS < "$STATE_DIR/passwords"
        read -r LEVEL < "$STATE_DIR/level" || { fail 'Seviye kaydı okunamadı; --new ile yeniden başlayabilirsin.'; return 1; }
        [[ $LEVEL =~ ^([1-9]|1[0-9]|2[0-6])$ && ${#PASSWORDS[@]} -eq 25 ]] || { fail 'Kayıt bozuk; --new ile yeniden başlayabilirsin.'; return 1; }
        [[ ${PASSWORDS[2]} == '-rwx--xrw-' && ${PASSWORDS[23]} == verification && ${PASSWORDS[24]} == yahni ]] || {
            fail 'Kayıt bozuk: özel seviye parolaları geçersiz.'; return 1;
        }
        for ((index=0; index<25; index++)); do
            ((index == 2 || index == 23)) && continue
            value=${PASSWORDS[index]}
            [[ $value =~ ^[[:alpha:]]{5}$ ]] || { fail 'Kayıt bozuk: parolalar beş harfli olmalı.'; return 1; }
        done
        if [[ ! -f "$STATE_DIR/completed" ]]; then
            # Eski kayıtlar tamamlanma geçmişi tutmuyordu. Geçiş sırasında
            # kayıtlı seviyeden önceki seviyeleri tamamlanmış kabul et.
            : > "$STATE_DIR/completed"
            local previous
            for ((previous=1; previous<LEVEL; previous++)); do
                printf '%s\n' "$previous" >> "$STATE_DIR/completed"
            done
        fi
        while IFS= read -r value || [[ -n $value ]]; do
            [[ $value =~ ^([1-9]|1[0-9]|2[0-5])$ ]] || { fail 'Kayıt bozuk: tamamlanan seviye listesi geçersiz.'; return 1; }
        done < "$STATE_DIR/completed"
    fi
    if ((LEVEL == 26)); then
        LEVEL=25; finished=1
        say 'Bu oyun tamamlanmış. flashback ile tekrar oynayabilir veya hardreset ile başa dönebilirsin.'
    fi
    setup_level || return 1
    # Tamamlanmış oyunu yalnızca açmak, bitiş kaydını geri almaz.
    if ((finished)); then save_level 26 || return 1; fi
    return 0
}

main() {
    local fresh=0 line dependency status
    while (($#)); do
        case "$1" in
            --new) fresh=1; shift ;;
            --state-dir)
                (($# >= 2)) || { fail 'Kayıt dizini eksik.'; return 1; }
                STATE_DIR=$2; shift 2 ;;
            --help|-h)
                say 'Kullanım: bash gnulinux101.sh [--new] [--state-dir DIZIN]'
                say 'Oyun içinde: görev, yardım, parola <kelime>, flashback <seviye>, gerisar, hardreset, çıkış'; return ;;
            *) fail "Bilinmeyen seçenek: $1"; return 1 ;;
        esac
    done
    for dependency in realpath od shuf stat cmp find grep sed awk less nano flock; do
        command -v "$dependency" >/dev/null || { fail "Gerekli program bulunamadı: $dependency"; return 1; }
    done
    umask 022
    if init_state "$fresh"; then :
    else
        status=$?
        if ((status == 2)); then return 0; fi
        return "$status"
    fi
    say 'GNU/Linux 101 — Terminal Oyunu'
    say 'Bu kontrollü eğitim terminalidir; gerçek sisteme paket kurulmaz.'
    say 'Ev dizinin: /home/user. Rehber: yardım | Görev: görev | Çıkış: çıkış'
    say 'Baştan başlamak için hardreset yaz: mevcut oyun alanı sıfırlanır ve 1. seviyeye dönersin.'
    say 'Tekrar için flashback <seviye> ile geçilmiş bir seviyeye dön; gerisar ile mevcut seviyeyi yeniden başlat.'
    say 'Parolalar beş harfli, anlamlı Türkçe kelimelerdir (örnek: yahni).'
    say 'İstisnalar: 3. seviyede 10 karakterlik dosya türü/izin alanı, 24. seviyede yardım metnindeki kelime kullanılır.'
    say 'Bulduğun parolayı parola <kelime> biçiminde gir; örneğin: parola yahni.'
    say 'Kaldığın seviye kaydedilir; yeniden açınca o seviye baştan kurulur.'
    show_task
    while ((DONE == 0)); do
        if [[ -t 0 ]]; then
            if ((LEVEL == 4 || LEVEL == 8 || LEVEL == 10)); then printf 'oyuncu:???$ '
            else printf 'oyuncu:%s$ ' "$(virtual_path "$CWD")"; fi
        fi
        IFS= read -r line || [[ -n $line ]] || break
        process_line "$line"
    done
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi
