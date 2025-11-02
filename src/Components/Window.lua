-- i will rewrite this someday
local UserInputService = game:GetService("UserInputService")
local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
local Camera = game:GetService("Workspace").CurrentCamera
local TweenService = game:GetService("TweenService") -- Added TweenService

local Root = script.Parent.Parent
local Flipper = require(Root.Packages.Flipper)
local Creator = require(Root.Creator)
local Acrylic = require(Root.Acrylic)
local Assets = require(script.Parent.Assets)
local Components = script.Parent

local Spring = Flipper.Spring.new
local Instant = Flipper.Instant.new
local New = Creator.New

return function(Config)
	local Library = require(Root)

	local Window = {
		Minimized = false,
		Maximized = false,
		Size = Config.Size,
		CurrentPos = 0,
		TabWidth = 0,
		Position = UDim2.fromOffset(
			Camera.ViewportSize.X / 2 - Config.Size.X.Offset / 2,
			Camera.ViewportSize.Y / 2 - Config.Size.Y.Offset / 2
		),
	}

	local Dragging, DragInput, MousePos, StartPos = false
	local Resizing, ResizePos = false
	local MinimizeNotif = false -- Still here, but the logic is now in Window:Minimize()

    -- ANIMATION CONSTANTS
    local ANIM_DURATION = 0.5
    local START_Y_POS = Window.Position.Y.Offset
    local END_Y_POS = START_Y_POS + 50 -- 50 pixels down for fade out
    local AnimDebounce = false

    -- NOTIFICATION CONSTANTS
    local NOTICE_WIDTH = 200
    local NOTICE_HEIGHT = 35
    local NOTICE_Y_OFFSET_TOP = 25

	Window.AcrylicPaint = Acrylic.AcrylicPaint()
	Window.TabWidth = Config.TabWidth

	local Selector = New("Frame", {
		Size = UDim2.fromOffset(4, 0),
		BackgroundColor3 = Color3.fromRGB(76, 194, 255),
		Position = UDim2.fromOffset(0, 17),
		AnchorPoint = Vector2.new(0, 0.5),
		ThemeTag = {
			BackgroundColor3 = "Accent",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 2),
		}),
	})

	local ResizeStartFrame = New("Frame", {
		Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -20, 1, -20),
	})

	Window.TabHolder = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarImageTransparency = 1,
		ScrollBarThickness = 0,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 4),
		}),
	})

	local TabFrame = New("Frame", {
		Size = UDim2.new(0, Window.TabWidth, 1, -66),
		Position = UDim2.new(0, 12, 0, 54),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, {
		Window.TabHolder,
		Selector,
	})

	Window.TabDisplay = New("TextLabel", {
		RichText = true,
		Text = "Tab",
		TextTransparency = 0,
		FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
		TextSize = 28,
		TextXAlignment = "Left",
		TextYAlignment = "Center",
		Size = UDim2.new(1, -16, 0, 28),
		Position = UDim2.fromOffset(Window.TabWidth + 26, 56),
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	Window.ContainerHolder = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})

	Window.ContainerAnim = New("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})

	Window.ContainerCanvas = New("Frame", {
		Size = UDim2.new(1, -Window.TabWidth - 32, 1, -102),
		Position = UDim2.fromOffset(Window.TabWidth + 26, 90),
		BackgroundTransparency = 1,
	}, {
		Window.ContainerAnim,
		Window.ContainerHolder
	})

	Window.Root = New("Frame", {
		BackgroundTransparency = 1,
		Size = Window.Size,
		Position = Window.Position,
		Parent = Config.Parent,
	}, {
		Window.AcrylicPaint.Frame,
		Window.TabDisplay,
		Window.ContainerCanvas,
		TabFrame,
		ResizeStartFrame,
	})

	Window.TitleBar = require(script.Parent.TitleBar)({
		Title = Config.Title,
		SubTitle = Config.SubTitle,
		Parent = Window.Root,
		Window = Window,
	})

	if require(Root).UseAcrylic then
		Window.AcrylicPaint.AddParent(Window.Root)
	end

	local SizeMotor = Flipper.GroupMotor.new({
		X = Window.Size.X.Offset,
		Y = Window.Size.Y.Offset,
	})

	local PosMotor = Flipper.GroupMotor.new({
		X = Window.Position.X.Offset,
		Y = Window.Position.Y.Offset,
	})

	Window.SelectorPosMotor = Flipper.SingleMotor.new(17)
	Window.SelectorSizeMotor = Flipper.SingleMotor.new(0)
	Window.ContainerBackMotor = Flipper.SingleMotor.new(0)
	Window.ContainerPosMotor = Flipper.SingleMotor.new(94)

	SizeMotor:onStep(function(values)
		Window.Root.Size = UDim2.new(0, values.X, 0, values.Y)
	end)

	PosMotor:onStep(function(values)
		Window.Root.Position = UDim2.new(0, values.X, 0, values.Y)
	end)

	local LastValue = 0
	local LastTime = 0
	Window.SelectorPosMotor:onStep(function(Value)
		Selector.Position = UDim2.new(0, 0, 0, Value + 17)
		local Now = tick()
		local DeltaTime = Now - LastTime

		if LastValue ~= nil then
			Window.SelectorSizeMotor:setGoal(Spring((math.abs(Value - LastValue) / (DeltaTime * 60)) + 16))
			LastValue = Value
		end
		LastTime = Now
	end)

	Window.SelectorSizeMotor:onStep(function(Value)
		Selector.Size = UDim2.new(0, 4, 0, Value)
	end)

	Window.ContainerBackMotor:onStep(function(Value)
		Window.ContainerAnim.GroupTransparency = Value
	end)

	Window.ContainerPosMotor:onStep(function(Value)
		Window.ContainerAnim.Position = UDim2.fromOffset(0, Value)
	end)

	local OldSizeX
	local OldSizeY
	Window.Maximize = function(Value, NoPos, Instant)
		Window.Maximized = Value
		Window.TitleBar.MaxButton.Frame.Icon.Image = Value and Assets.Restore or Assets.Max

		if Value then
			OldSizeX = Window.Size.X.Offset
			OldSizeY = Window.Size.Y.Offset
		end
		local SizeX = Value and Camera.ViewportSize.X or OldSizeX
		local SizeY = Value and Camera.ViewportSize.Y or OldSizeY
		SizeMotor:setGoal({
			X = Flipper[Instant and "Instant" or "Spring"].new(SizeX, { frequency = 6 }),
			Y = Flipper[Instant and "Instant" or "Spring"].new(SizeY, { frequency = 6 }),
		})
		Window.Size = UDim2.fromOffset(SizeX, SizeY)

		if not NoPos then
			PosMotor:setGoal({
				X = Spring(Value and 0 or Window.Position.X.Offset, { frequency = 6 }),
				Y = Spring(Value and 0 or Window.Position.Y.Offset, { frequency = 6 }),
			})
		end
	end
    
    
    -- FLUENT-STYLE NOTIFICATION FUNCTION (Used only by the Close Button)
    local function Fluent_Notify()
        local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        
        local GuiName = "FluentTopActionButton"
        if PlayerGui:FindFirstChild(GuiName) then
            PlayerGui[GuiName]:Destroy()
        end

        local ScreenGui = New("ScreenGui", {
            Name = GuiName,
            DisplayOrder = 999,
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            Parent = PlayerGui,
        })

        local RootNotify = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, NOTICE_WIDTH, 0, NOTICE_HEIGHT),
            Position = UDim2.new(0.5, 0, 0, -NOTICE_HEIGHT),
            AnchorPoint = Vector2.new(0.5, 0),
            Parent = ScreenGui,
        })

        -- Mimics Acrylic Paint
        local AcrylicPaintFrame = New("Frame", {
            BackgroundColor3 = Color3.fromRGB(25, 25, 25),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            Parent = RootNotify
        })
        New("UICorner", {CornerRadius = UDim.new(0, 4)}, nil).Parent = AcrylicPaintFrame

        New("TextLabel", {
            Text = "Show",
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
            TextSize = 13,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Parent = RootNotify,
        })

        local ActionButton = New("TextButton", {
            Text = "",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = RootNotify,
        })

        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
        
        local function fadeIn()
            TweenService:Create(RootNotify, tweenInfo, {
                Position = UDim2.new(0.5, 0, 0, NOTICE_Y_OFFSET_TOP)
            }):Play()
        end
        
        ActionButton.MouseButton1Click:Connect(function()
            -- 1. Trigger the main window's show animation
            Window:AnimateShow()
            -- 2. INSTANTLY destroy the notification GUI (Crucial for speed)
            if ScreenGui and ScreenGui.Parent then
                ScreenGui:Destroy()
            end
        end)
        
        fadeIn()
    end

    -- NEW: Window Show Animation (Reverse of Close)
    function Window:AnimateShow()
        if not Window.Minimized or AnimDebounce then return end
        AnimDebounce = true
        
        Window.Root.Visible = true
        Window.Minimized = false

        -- 1. Animate main frame position (back to start)
        PosMotor:setGoal({
            X = Spring(Window.Position.X.Offset, { frequency = 6 }),
            Y = Spring(START_Y_POS, { frequency = 6 }),
        })

        -- 2. Animate all elements' transparency (fade in)
        -- We will assume the default transparency for acrylic is 0.5
        TweenService:Create(Window.AcrylicPaint.Frame, TweenInfo.new(ANIM_DURATION, Enum.EasingStyle.Exponential), {
            BackgroundTransparency = 0.5
        }):Play()

        -- Fade in all contents (TitleBar, Container, etc.)
        for _, child in Window.Root:GetChildren() do
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("ScrollingFrame") or child:IsA("Frame") or child:IsA("CanvasGroup") then
                TweenService:Create(child, TweenInfo.new(ANIM_DURATION, Enum.EasingStyle.Exponential), {
                    BackgroundTransparency = child.BackgroundTransparency > 0.5 and 0.5 or 0, -- Restore to initial transparency
                    GroupTransparency = 0,
                    TextTransparency = 0,
                }):Play()
            end
        end
        
        task.wait(ANIM_DURATION)
        AnimDebounce = false
    end

    -- NEW: Window Close Animation (Downward Fade)
    function Window:AnimateClose()
        if Window.Minimized or AnimDebounce then return end
        AnimDebounce = true
        
        Window.Minimized = true

        -- 1. Show the Fluent Notification immediately
        Fluent_Notify()

        -- 2. Animate main frame position (downward)
        PosMotor:setGoal({
            X = Spring(Window.Position.X.Offset, { frequency = 6 }),
            Y = Spring(END_Y_POS, { frequency = 6 }),
        })

        -- 3. Animate all elements' transparency (fade out)
        TweenService:Create(Window.AcrylicPaint.Frame, TweenInfo.new(ANIM_DURATION, Enum.EasingStyle.Exponential), {
            BackgroundTransparency = 1
        }):Play()

        for _, child in Window.Root:GetChildren() do
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("ScrollingFrame") or child:IsA("Frame") or child:IsA("CanvasGroup") then
                TweenService:Create(child, TweenInfo.new(ANIM_DURATION, Enum.EasingStyle.Exponential), {
                    BackgroundTransparency = 1,
                    GroupTransparency = 1,
                    TextTransparency = 1,
                }):Play()
            end
        end
        
        task.wait(ANIM_DURATION)
        Window.Root.Visible = false
        AnimDebounce = false
    end

    -- Connect the X button to the new close animation
    -- Assuming your TitleBar module exposes a 'CloseButton' property (which contains a Frame)
    local CloseButton = Window.TitleBar.CloseButton.Frame or Window.TitleBar.CloseButton 

    if CloseButton and CloseButton:IsA("GuiObject") then
        Creator.AddSignal(CloseButton.MouseButton1Click, function()
            Window:AnimateClose()
        end)
    end
    -- END: X Button Connection

	Creator.AddSignal(Window.TitleBar.Frame.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			Dragging = true
			MousePos = Input.Position
			StartPos = Window.Root.Position

			if Window.Maximized then
				StartPos = UDim2.fromOffset(
					Mouse.X - (Mouse.X * ((OldSizeX - 100) / Window.Root.AbsoluteSize.X)),
					Mouse.Y - (Mouse.Y * (OldSizeY / Window.Root.AbsoluteSize.Y))
				)
			end

			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)

	Creator.AddSignal(Window.TitleBar.Frame.InputChanged, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseMovement
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			DragInput = Input
		end
	end)

	Creator.AddSignal(ResizeStartFrame.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			Resizing = true
			ResizePos = Input.Position
		end
	end)

	Creator.AddSignal(UserInputService.InputChanged, function(Input)
		if Input == DragInput and Dragging then
			local Delta = Input.Position - MousePos
			Window.Position = UDim2.fromOffset(StartPos.X.Offset + Delta.X, StartPos.Y.Offset + Delta.Y)
			PosMotor:setGoal({
				X = Instant(Window.Position.X.Offset),
				Y = Instant(Window.Position.Y.Offset),
			})

			if Window.Maximized then
				Window.Maximize(false, true, true)
			end
		end

		if
			(Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
			and Resizing
		then
			local Delta = Input.Position - ResizePos
			local StartSize = Window.Size

			local TargetSize = Vector3.new(StartSize.X.Offset, StartSize.Y.Offset, 0) + Vector3.new(1, 1, 0) * Delta
			local TargetSizeClamped =
				Vector2.new(math.clamp(TargetSize.X, 470, 2048), math.clamp(TargetSize.Y, 380, 2048))

			SizeMotor:setGoal({
				X = Flipper.Instant.new(TargetSizeClamped.X),
				Y = Flipper.Instant.new(TargetSizeClamped.Y),
			})
		end
	end)

	Creator.AddSignal(UserInputService.InputEnded, function(Input)
		if Resizing == true or Input.UserInputType == Enum.UserInputType.Touch then
			Resizing = false
			Window.Size = UDim2.fromOffset(SizeMotor:getValue().X, SizeMotor:getValue().Y)
		end
	end)

	Creator.AddSignal(Window.TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		Window.TabHolder.CanvasSize = UDim2.new(0, 0, 0, Window.TabHolder.UIListLayout.AbsoluteContentSize.Y)
	end)

	Creator.AddSignal(UserInputService.InputBegan, function(Input)
		if
			type(Library.MinimizeKeybind) == "table"
			and Library.MinimizeKeybind.Type == "Keybind"
			and not UserInputService:GetFocusedTextBox()
		then
			if Input.KeyCode.Name == Library.MinimizeKeybind.Value then
				Window:Minimize()
			end
		elseif Input.KeyCode == Library.MinimizeKey and not UserInputService:GetFocusedTextBox() then
			Window:Minimize()
		end
	end)

    -- Modified Minimize() to act as a toggle using the new animation functions
	function Window:Minimize()
		if Window.Minimized then
            -- If minimized (hidden), show it
			Window:AnimateShow()
		else
            -- If visible, close it (downward fade + notification)
			Window:AnimateClose()
		end
        
        -- The original MinimizeNotif logic, now just using Library:Notify for the keybind
        if not MinimizeNotif and Window.Minimized then
			MinimizeNotif = true
			local Key = Library.MinimizeKeybind and Library.MinimizeKeybind.Value or Library.MinimizeKey.Name
			Library:Notify({
				Title = "Interface",
				Content = "Press " .. Key .. " to toggle the interface.",
				Duration = 6
			})
		end
	end

	function Window:Destroy()
		if require(Root).UseAcrylic then
			Window.AcrylicPaint.Model:Destroy()
		end
		Window.Root:Destroy()
	end

	local DialogModule = require(Components.Dialog):Init(Window)
	function Window:Dialog(Config)
		local Dialog = DialogModule:Create()
		Dialog.Title.Text = Config.Title

		local Content = New("TextLabel", {
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
			Text = Config.Content,
			TextColor3 = Color3.fromRGB(240, 240, 240),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Size = UDim2.new(1, -40, 1, 0),
			Position = UDim2.fromOffset(20, 60),
			BackgroundTransparency = 1,
			Parent = Dialog.Root,
			ClipsDescendants = false,
			ThemeTag = {
				TextColor3 = "Text",
			},
		})

		New("UISizeConstraint", {
			MinSize = Vector2.new(300, 165),
			MaxSize = Vector2.new(620, math.huge),
			Parent = Dialog.Root,
		})

		Dialog.Root.Size = UDim2.fromOffset(Content.TextBounds.X + 40, 165)
		if Content.TextBounds.X + 40 > Window.Size.X.Offset - 120 then
			Dialog.Root.Size = UDim2.fromOffset(Window.Size.X.Offset - 120, 165)
			Content.TextWrapped = true
			Dialog.Root.Size = UDim2.fromOffset(Window.Size.X.Offset - 120, Content.TextBounds.Y + 150)
		end

		for _, Button in next, Config.Buttons do
			Dialog:Button(Button.Title, Button.Callback)
		end

		Dialog:Open()
	end

	local TabModule = require(Components.Tab):Init(Window)
	function Window:AddTab(TabConfig)
		return TabModule:New(TabConfig.Title, TabConfig.Icon, Window.TabHolder)
	end

	function Window:SelectTab(Tab)
		TabModule:SelectTab(1)
	end

	Creator.AddSignal(Window.TabHolder:GetPropertyChangedSignal("CanvasPosition"), function()
		LastValue = TabModule:GetCurrentTabPos() + 16
		LastTime = 0
		Window.SelectorPosMotor:setGoal(Instant(TabModule:GetCurrentTabPos()))
	end)

	return Window
end
