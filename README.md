# GNU/Linux 101

## English

### Training Materials

This game was developed as part of GaziSiber's GNU/Linux101 training program. Video lessons covering fundamental concepts, terminal usage, and puzzle solutions are available on YouTube.

**[GNU/Linux101 YouTube Playlist](https://www.youtube.com/playlist?list=PLGvhlc2Qg6j8)**

**GNU/Linux 101** is an open-source, 25-level educational game designed to develop fundamental terminal skills through hands-on practice.

Built with Bash, the game provides a controlled terminal environment where players complete tasks and progress through increasingly challenging problems.

The project was developed as part of the GNU/Linux 101 training program organized by the Free Software and Linux Team of GaziSiber at Gazi University.

### Getting Started

The game provides two independent versions:

| Language | File |
|---|---|
| Turkish | `gnulinux101-tr.sh` |
| English | `gnulinux101-en.sh` |

A GNU/Linux environment with Bash 5 or later is recommended. The game uses standard GNU utilities, along with `less`, `nano`, and `flock`.

To launch the English version:

```bash
bash gnulinux101-en.sh
```

For launch options, use `--help`. A detailed in-game guide is available through the `help` command.

### Progress and Safety

- Progress is saved automatically; the current level is rebuilt when the game restarts.
- The Turkish and English versions use separate save directories by default.
- File operations take place within a dedicated game environment.
- Package management and file ownership operations are simulated.

The game is not a fully isolated system sandbox. When specifying a custom save directory, avoid directories containing personal files.

Developed with GPT-6.1 Sol

---

## Türkçe

### Eğitim Materyalleri

Bu oyun, GaziSiber'in GNU/Linux101 eğitimi kapsamında geliştirilmiştir. Temel kavramları, terminal kullanımını ve bulmaca çözümlerini kapsayan video derslere YouTube üzerinden erişebilirsiniz.

**[GNU/Linux101 YouTube Oynatma Listesi](https://www.youtube.com/playlist?list=PLGvhlc2Qg6j8)**

**GNU/Linux 101**, temel terminal becerilerini uygulamalı olarak geliştirmek amacıyla hazırlanmış, 25 seviyeden oluşan açık kaynaklı bir eğitim oyunudur.

Bash ile geliştirilen oyun, kullanıcıların kontrollü bir terminal ortamında görevleri tamamlayarak ilerlemesini sağlar. Her seviyede farklı bir problem sunulur ve öğrenilen bilgilerin bağımsız olarak uygulanması hedeflenir.

Proje, Gazi Üniversitesi Siber Güvenlik ve AR-GE Topluluğu (GaziSiber) bünyesindeki Özgür Yazılım ve Linux Ekibi'nin GNU/Linux 101 eğitimleri kapsamında hazırlanmıştır.

### Başlangıç

Oyun, Türkçe ve İngilizce olmak üzere iki bağımsız sürüm içerir.

| Dil | Dosya |
|---|---|
| Türkçe | `gnulinux101-tr.sh` |
| İngilizce | `gnulinux101-en.sh` |

GNU/Linux ortamında Bash 5 veya üzeri önerilir. Oyun, temel GNU araçları ile `less`, `nano` ve `flock` bağımlılıklarını kullanır.

Türkçe sürümü başlatmak için:

```bash
bash gnulinux101-tr.sh
```

İngilizce sürümü başlatmak için:

```bash
bash gnulinux101-en.sh
```

Komut satırı seçenekleri için `--help` parametresini kullanabilirsiniz. Oyun içindeki ayrıntılı rehbere `yardım` komutuyla erişebilirsiniz.

### İlerleme ve güvenlik

- İlerleme otomatik kaydedilir; oyun yeniden açıldığında mevcut seviye baştan oluşturulur.
- Türkçe ve İngilizce sürümler varsayılan olarak ayrı kayıt dizinleri kullanır.
- Dosya işlemleri, gerçek kullanıcı dosyalarından ayrılmış bir oyun alanında gerçekleştirilir.
- Paket yönetimi ve dosya sahipliği işlemleri simüle edilir.

Oyun, tam kapsamlı bir sistem yalıtımı sağlamaz. Özel kayıt dizini kullanırken kişisel dosyalarınızın bulunduğu bir dizini seçmeyin.

GPT-6.1 Sol ile geliştirilmiştir.
