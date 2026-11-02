# 체다-mine 수집기 러너 (스케줄러용). 08:00~02:00 30분마다 실행.
# 흐름: 세션점검(오프스크린) → 수집 → 암호화 → 발송 → 창전체닫기 → 푸시
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here
$py     = "C:\Users\ddabl\AppData\Local\Python\pythoncore-3.14-64\python.exe"
$adauto = "C:\Users\ddabl\Desktop\ad_auto"
$log    = Join-Path $here "collect.log"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# 0) 세션 점검·자동복구(오프스크린, 화면 안 뜸) + 복구불가 시 커머스-체다 알림
$sess = & $py (Join-Path $adauto "session_check.py") | Out-String

# 1) 수집 → 암호화
$out = & $py collector.py | Out-String
$enc = & $py encrypt.py | Out-String

# 2) 슬랙 자동발송: 이력은 매번 기록, 12/16/21시만 실제 발송(20% 이상차→커머스체다 점검요청)
$sendHours = @(12, 16, 21)
$hour = [int](Get-Date -Format "HH")
$sendArg = $(if ($sendHours -contains $hour) { "--send" } else { "" })
$snd = & $py slack_send.py $sendArg | Out-String

# 3) 자동화 크롬 전체 닫기(WING·GFA·카카오·9226 등, 화면 깔끔)
$cls = & $py (Join-Path $adauto "close_all.py") | Out-String

# 로그
"[$(Get-Date -Format s)]`nSESSION: $sess`nCOLLECT: $out`nENCRYPT: $enc`nSEND: $snd`nCLOSE: $cls" |
    Out-File -FilePath $log -Append -Encoding utf8

# 4) 암호화 데이터만 공개 repo에 푸시
git add data/data.enc 2>$null
git commit -q -m "update $(Get-Date -Format 'yyyy-MM-dd HH:mm')" 2>$null
git push -q 2>$null
