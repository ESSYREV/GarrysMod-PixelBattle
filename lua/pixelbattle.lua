local pixelScale = 2
local pixel = {}
local pixeldraw_delay = 15 -- sec
local last_writed_pixel = 0
local pixelPos = nil
if _G.essyrev_pixelate == nil then _G.essyrev_pixelate = {} end

local cs = 0 -- чтоб не спамило при одном нажатии (несколько раз пишет, что рисовать нельзя)

-- Создаем таблицу для новой entity
ENT = {}

-- Указываем базовую таблицу - базовый тип entity
ENT.Base = "base_gmodentity"

-- Указываем имя для entity
ENT.PrintName = "P".."i".."x".."e".."l".."a".."t".."e"

-- Указываем категорию, в которую будет добавлена entity в меню spawn menu
ENT.Category = "E".."s".."y".."r".."e".."v"

-- Указываем модель для entity
ENT.Model = "models/hunter/plates/plate2x6.mdl"

-- Включаем возможность физической интеракции с entity
ENT.PhysgunDisabled = false
ENT.CanPickup = true

-- Включаем возможность использования entity
ENT.Spawnable = true
ENT.AdminOnly = false

local esrvcustomMaterial = nil

if CLIENT then


    local exampleRT = GetRenderTarget( "esrv.pixelart17", 1024, 1024 )
    local paints = {}
    local scale = 2

    local materialParams = {
        ["$vertexcolor"] = 1,
        ["$model"] = 1,
        ["$translucent"] = 1,
        ["$alpha"] = 0
    }

    esrvcustomMaterial = CreateMaterial( "esrv.pixelart17", "UnlitGeneric", {
        ["$basetexture"] = exampleRT:GetName(), -- You can use "example_rt" as well
        ["$translucent"] = 1,
        ["$vertexcolor"] = 1
    } )



    local function rendertarget()
        render.PushRenderTarget( exampleRT )
        cam.Start2D()
        render.Clear(0,0,0,255)
        draw.RoundedBox( 0, 0,0, 1024,1024, Color( 0,0,0 ) )
        for _,tbl in pairs(_G.essyrev_pixelate) do
            surface.SetDrawColor(tbl[3], tbl[4], tbl[5])
            surface.DrawRect(tbl[1], tbl[2], pixelScale*2, pixelScale*5.5)
        end

        cam.End2D()
        render.PopRenderTarget()
    end

    net.Receive("esrv.pixelate",function()
        table.insert(_G.essyrev_pixelate,net.ReadTable())
        rendertarget()
    end)

    hook.Add( "InitPostEntity", "esrv.pixelate_load", function()
        net.Start( "esrv.pixelate_load" )
        net.SendToServer()
    end)

    net.Receive("esrv.pixelate_load",function()
        _G.essyrev_pixelate = net.ReadTable()
        rendertarget()
    end)

    hook.Add("KeyPress","esrv.pixelate_write_pixel",function(ply,key)

        if (not (LocalPlayer():GetEyeTrace().Entity:GetClass() == "esrv_pixelate")) then return end

        if pixelPos == nil then return end
        if not (key==32) then return end

        if cs > CurTime() then return end cs = CurTime() + 0.1

        if last_writed_pixel > CurTime() then 
            local time = last_writed_pixel - CurTime()
            time = time - time%0.1
            LocalPlayer():PrintMessage(3,LocalPlayer():GetName()..", в следующий раз вы сможете нарисовать свой пиксель через "..time.." сек.")
            return
        end


            last_writed_pixel = CurTime() + pixeldraw_delay
            local plColor = team.GetColor( LocalPlayer():Team() )
            pixel = {pixelPos[1]/2*7.2-9,pixelPos[2]*10.8-27, plColor["r"],plColor["g"],plColor["b"]}

            net.Start("esrv.pixelate")
                net.WriteTable(pixel)
            net.SendToServer()

        end)

end



-- Инициализация entity
function ENT:Initialize()
    -- Установка модели и физических свойств
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    
    -- Получение и настройка физического объекта
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        -- Если объект существует, устанавливаем свойства
        phys:SetMass(100)
        phys:SetDamping(0, 10)
        phys:Wake()
    end
end

-- Функция для отрисовки информации entity
function ENT:Draw()
    -- Отрисовываем модель
    self:DrawModel()


    -- Отрисовываем текст над моделью
    local pos = self:GetPos() + self:GetUp() * 10
    local ang = self:GetAngles() + Angle(0,0,-90)
    local lcl, angg = self:LocalToWorld(Vector(47,142,2))
    ang:RotateAroundAxis(self:GetRight(), 90)
    ang:RotateAroundAxis(self:GetForward(), 90)
    
    local Plotnost = 1
    local height = 95.4
    local width = 285.2


    local OffsetX = Plotnost/2 - 2
    local OffsetY = Plotnost/2 - 2



    local LocalPos = WorldToLocal(LocalPlayer():GetEyeTrace().HitPos, Angle(), self:LocalToWorld(Vector(-height/2, -width/2, 0)), self:GetAngles())
    local ScreenPos = Vector((LocalPos[1] - LocalPos[1] % Plotnost) / Plotnost, (LocalPos[2] - LocalPos[2] % Plotnost) / Plotnost, 0)
    local HoloPos = Vector(LocalPos[1] - LocalPos[1] % Plotnost + OffsetX, LocalPos[2] - LocalPos[2] % Plotnost + OffsetY, 0)


    cam.Start3D2D(lcl, ang, 1)
        if (LocalPlayer():GetEyeTrace().Entity:GetClass() == "esrv_pixelate") then

            pixelPos = {width - HoloPos[2],height - HoloPos[1]}

            surface.SetDrawColor( 255, 255, 255, 255 )
            surface.SetMaterial( esrvcustomMaterial )
            surface.DrawTexturedRect( 0, 0, 2048/7.2, 1024/10.8 )       -- 7.2          10.8

            surface.SetDrawColor( 255, 0, 0, 255 )
            surface.DrawRect(pixelPos[1]-2.3,pixelPos[2]-2,1,1)

        else
            draw.SimpleTextOutlined("Рисовать? Нажми E", "BudgetLabel", 25, 0, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(255, 255, 0))
            draw.SimpleTextOutlined("(и наведи на меня курсор)", "BudgetLabel", 25, 55, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(255, 255, 0))
        end
    cam.End3D2D()



end

function ENT:OnRemove()
    timer.Remove("esrv.pixelbattle")
end

-- Регистрируем новую entity
scripted_ents.Register(ENT, "esrv_pixelate")


if SERVER then
    local pixelate_delay = 0.5 --sec
    util.AddNetworkString("esrv.pixelate")
    net.Receive("esrv.pixelate",function(_,ply)
        if (ply.pixeldraw_delay or 0) > CurTime() then 
            ply:PrintMessage(3,ply:Nick()..", и всё-таки, следующий пиксель только через "..pixeldraw_delay.." времени))")
            return
        end
        ply.pixeldraw_delay = CurTime() + pixeldraw_delay
        local pixel = net.ReadTable()

        table.insert(_G.essyrev_pixelate,pixel)

        net.Start( "esrv.pixelate" )
            net.WriteTable( pixel )
        net.Broadcast()

    end)

    timer.Create("pixelate.autosave",60,0,function()
        file.Write( "pixelate.txt", util.TableToJSON( _G.essyrev_pixelate ) )
    end)

    util.AddNetworkString( "esrv.pixelate_load" )

    net.Receive( "esrv.pixelate_load", function( len, ply )
        if IsValid(ply.pixelater_loaded) then return end
        ply.pixelater_loaded = true

        file.Write( "pixelate.txt", util.TableToJSON( _G.essyrev_pixelate ) )

        timer.Simple(5,function()
            net.Start("esrv.pixelate_load")
                net.WriteTable(_G.essyrev_pixelate)
            net.Send(ply)
        end)

    end)

    hook.Add( "InitPostEntity", "esrv.load_all_pixels_on_start", function()
        _G.essyrev_pixelate = util.JSONToTable(  file.Read( "pixelate.txt", "DATA" ) )
    end )

end

