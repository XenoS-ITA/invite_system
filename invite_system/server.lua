local get_adapt   = LoadResourceFile(GetCurrentResourceName(), "files/adaptive_cards.js")
local adapt_cards = json.decode(get_adapt)[1]

function ShowCard(_deferrals, _source)
    adapt_cards.body[2].color = "Default"
    adapt_cards.body[2].text  = "Thanks for joining "..Config.ServerName.."! (submit blank if you dont have an invite code)"

    _deferrals.presentCard(adapt_cards, function(data)
        -- Submit
        local all_code = ""
        local inv_code = MySQL.Sync.fetchAll("SELECT code FROM invite_code WHERE used=@used",{['@used'] = 0})

        for i=1, #inv_code do
            all_code = all_code..inv_code[i].code
        end    

        if string.find(all_code, data.invite) and data.invite ~= nil and data.invite ~= "" then
            -- Invite code is valid
            MySQL.Sync.execute('UPDATE invite_code SET used=@used, used_by=@used_by WHERE code=@code',{
                ['@used'] = 1,
                ['@used_by'] = GetPlayerIdentifiers(_source)[1],
                ['@code'] = data.invite
            })

            GenerateInviteCodeAndInserIntoDb(GetPlayerIdentifiers(_source)[1])
            local code_owner_identifier = MySQL.Sync.fetchAll("SELECT identifier FROM invite_code WHERE code=@code",{
                ['@code'] = data.invite
            })

            local bank = MySQL.Sync.fetchAll("SELECT bank FROM users WHERE identifier=@identifier",{
                ['@identifier'] = code_owner_identifier[1].identifier
            })

            MySQL.Sync.execute('UPDATE users SET bank=@bank WHERE identifier=@identifier',{
                ['@bank'] = bank[1].bank + Config.InvitationReward,
                ['@identifier'] = code_owner_identifier[1].identifier
            })

            -- Give the reward to the player that own the code
            
            adapt_cards.body[2].color = "Good"
            adapt_cards.body[2].text  = "Code redeemed successfully!"

            _deferrals.presentCard(adapt_cards, function(data) -- Refresh Card
            end)
            Citizen.Wait(3000)
            _deferrals.done()
        else
            -- Invite code is invalid (no invitation code)

            adapt_cards.body[2].color = "Attention"
            adapt_cards.body[2].text  = "You have not entered an invitation code"

            _deferrals.presentCard(adapt_cards, function(data) -- Refresh Card
            end)
            GenerateInviteCodeAndInserIntoDb(GetPlayerIdentifiers(_source)[1])
            Wait(3000)
            _deferrals.done()
        end
    end)
end 

Citizen.CreateThread(function()
    AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
        local _source = source
        local _deferrals = deferrals

        _deferrals.defer()

        local code = GetCode(_source)
        -- Check if has already code registered

        if #code == 0 then
            -- Its first time that the player join
            ShowCard(_deferrals, _source)
        else
            -- The player have already invitation code
            _deferrals.done()
        end
    end)
end)

function GenerateRandomInviteCode()
    local _return = ""

    -- https://helloacm.com/random/
    if Config.UseOnlyNumber then
        PerformHttpRequest("https://random.justyy.workers.dev/api/random/?cached&n="..tonumber(Config.CodeLength).."&x=4", function(err, text, headers) _return = _return..tostring(text) end)
    else
        PerformHttpRequest("https://random.justyy.workers.dev/api/random/?cached&n="..tonumber(Config.CodeLength/2).."&x=1", function(err, text, headers) _return = _return..tostring(text) end)
        PerformHttpRequest("https://random.justyy.workers.dev/api/random/?cached&n="..tonumber(Config.CodeLength/2).."&x=2", function(err, text, headers) _return = _return..tostring(text) end)
    end
    Citizen.Wait(200)

    _return = string.gsub(_return, "\"", "")

    while _return == "" do
        Citizen.Wait(1)
    end

    if string.find(_return, "\"") then _return = string.gsub(_return, "\"", "") end

    return _return
end

function GenerateInviteCodeAndInserIntoDb(identifier)
    for i=1, Config.HowMuchCodeForPlayer do
        MySQL.Async.execute('INSERT INTO invite_code SET code=@code, identifier=@identifier',{
            ['@code'] = GenerateRandomInviteCode(),
            ['@identifier'] = identifier,
        })
    end
end

function GetCode(source)
    local identifier = GetPlayerIdentifiers(source)[1]

    local code = MySQL.Sync.fetchAll("SELECT * FROM invite_code WHERE identifier=@identifier",{['@identifier'] = identifier})
    return code
end

RegisterServerEvent("invite_system:Request")
AddEventHandler("invite_system:Request", function()
    local _source = source

    print(json.encode(GetCode(_source)))
    TriggerClientEvent("invite_system:Receive", _source, GetCode(_source))
end)