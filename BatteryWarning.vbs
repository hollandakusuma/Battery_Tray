
Option Explicit

Dim objWMI
Dim batteries
Dim battery
Dim level
Dim status
Dim warningShown

Set objWMI = GetObject("winmgmts:\\.\root\cimv2")

warningShown = False

Do
    Set batteries = objWMI.ExecQuery( _
        "SELECT * FROM Win32_Battery")

    For Each battery In batteries

        If Not IsNull(battery.EstimatedChargeRemaining) Then

            level = battery.EstimatedChargeRemaining
            status = battery.BatteryStatus

            ' Peringatan ketika baterai <= 20%
            ' dan tidak sedang diisi daya
            If level <= 20 And _
               (status = 1 Or status = 4 Or status = 5) Then

                If Not warningShown Then
                    MsgBox "Baterai laptop tersisa " & _
                        level & "%" & vbCrLf & _
                        "Segera hubungkan charger!", _
                        vbExclamation, _
                        "Peringatan Baterai"

                    warningShown = True
                End If

            ElseIf level > 20 Or status = 2 Then
                warningShown = False
            End If

        End If

    Next

    WScript.Sleep 5000
Loop
