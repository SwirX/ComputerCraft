local class = require("lib.sxui.core.class")
local Element = require("lib.sxui.core.element")
local Animator = require("lib.sxui.core.animator")

local Screen = class(Element)

function Screen:new(target)
    Element.new(self) -- call super
    self.target = target or term.current()
    if self.target.getSize then
        local tw, th = self.target.getSize()
        self.size = { scaleX = 0, offsetX = tw, scaleY = 0, offsetY = th }
    end
    self.position = { scaleX = 0, offsetX = 1, scaleY = 0, offsetY = 1 }
end

function Screen:draw()
    if not self.visible then return end

    self.target.setBackgroundColor(self.backgroundColor)
    self.target.clear()

    local sortedChildren = {}
    for _, c in ipairs(self.children) do table.insert(sortedChildren, c) end
    table.sort(sortedChildren, function(a, b) return a.zIndex < b.zIndex end)

    for _, c in ipairs(sortedChildren) do
        c:draw(self.target)
    end
end

function Screen:run()
    self.running = true
    self:draw()

    local animTimer = nil
    if Animator.hasActive() then
        animTimer = os.startTimer(0.05)
    end

    while self.running do
        local eventData = { os.pullEvent() }
        local event = eventData[1]

        -- Animation ticking
        if event == "timer" and eventData[2] == animTimer then
            if Animator.tick(os.clock()) then
                animTimer = os.startTimer(0.05)
            end
            self:draw()
        else
            -- Check if someone started an animation
            if Animator.hasActive() and not animTimer then
                animTimer = os.startTimer(0.05)
            end
        end

        -- Generate synthetic mouse_move on generic pointer actions
        if event == "mouse_click" or event == "mouse_drag" then
            self:handleEvent("mouse_move", eventData[3], eventData[4])
        elseif event == "monitor_touch" then
            self:handleEvent("mouse_move", eventData[2], eventData[3])
        end

        -- Distribute actual events
        local consumed = self:handleEvent(table.unpack(eventData))

        -- Redraw the screen if visual state could have changed
        if event == "mouse_click" or event == "mouse_drag" or event == "monitor_touch" or event == "key" or event == "char" or event == "mouse_up" or event == "mouse_scroll" then
            self:draw()
        end
    end
end

function Screen:stop()
    self.running = false
end

return Screen
