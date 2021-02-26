local invite = {}

RegisterCommand("invite", function(source, args, rawCommand)
    TriggerServerEvent("invite_system:Request")
    Citizen.Wait(300)
    local callback = ""

    for i=1, #invite do
        local used = ""
        if invite[i].used then
            used = '<p style="color:#e60f0b">Already claimed</p>'
        else
            used = '<p style="color:#13ed0c">Ready to be claimed</p>'
        end

        callback = callback.."Code - "..invite[i].code..""..used.."<br>"
    end

    TriggerEvent('chat:addMessage', {
        template = '<div style="  padding: 0.6vw;padding-top: 0.6vw;padding-bottom: 0.7vw;margin: 0.1vw;margin-left: 0.4vw;border-radius: 10px;background-color: rgba(29, 29, 29, 0.75);width: fit-content;max-width: 100%;overflow: hidden;word-break: break-word;"><strong>Invite system</strong><br></i>'..callback..'</div>',
        args = {}
    })
end)

RegisterNetEvent("invite_system:Receive")
AddEventHandler("invite_system:Receive", function(_invite)
    invite = _invite
end)