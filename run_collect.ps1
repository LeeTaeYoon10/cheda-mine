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
$sendHours = @()   # 발송은 ChedaMine_Send 태스크가 별도 처리
$hour = [int](Get-Date -Format "HH")
$out = & $py collector.py | Out-String
# 발송 시간이면 직전에 한번 더 수집 (세션점검 소요시간만큼 밀린 at 보정)
if ($sendHours -contains $hour) {
    $out2 = & $py collector.py | Out-String
    $out = $out2
}
$enc = & $py encrypt.py | Out-String

# 2) 슬랙 자동발송
$sendArg = $(if ($sendHours -contains $hour) { "--send" } else { "" })
$snd = & $py slack_send.py $sendArg | Out-String

# 3) 자동화 크롬 전체 닫기(WING·GFA·카카오·9226 등, 화면 깔끔)
$cls = & $py (Join-Path $adauto "close_all.py") | Out-String

# 로그
"[$(Get-Date -Format s)]`nSESSION: $sess`nCOLLECT: $out`nENCRYPT: $enc`nSEND: $snd`nCLOSE: $cls" |
    Out-File -FilePath $log -Append -Encoding utf8

# 4) 히스토리 암호화
$henc = & $py encrypt_history.py | Out-String

# 5) 암호화 데이터만 공개 repo에 푸시
git add data/data.enc data/history.enc 2>$null
git commit -q -m "update $(Get-Date -Format 'yyyy-MM-dd HH:mm')" 2>$null
git push -q 2>$null
