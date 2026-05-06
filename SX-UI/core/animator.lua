local Easing = {
    Linear = function(t, b, c, d) return c * t / d + b end,
    SineIn = function(t, b, c, d) return -c * math.cos(t / d * (math.pi / 2)) + c + b end,
    SineOut = function(t, b, c, d) return c * math.sin(t / d * (math.pi / 2)) + b end,
    SineInOut = function(t, b, c, d) return -c / 2 * (math.cos(math.pi * t / d) - 1) + b end,
    CubicIn = function(t, b, c, d) t = t / d; return c * math.pow(t, 3) + b end,
    CubicOut = function(t, b, c, d) t = t / d - 1; return c * (math.pow(t, 3) + 1) + b end,
    CubicInOut = function(t, b, c, d) t = t / (d / 2); if t < 1 then return c / 2 * math.pow(t, 3) + b end; t = t - 2; return c / 2 * (math.pow(t, 3) + 2) + b end,
    ExpoIn = function(t, b, c, d) return t == 0 and b or c * math.pow(2, 10 * (t / d - 1)) + b - c * 0.001 end,
    ExpoOut = function(t, b, c, d) return t == d and b + c or c * 1.001 * (-math.pow(2, -10 * t / d) + 1) + b end,
    ExpoInOut = function(t, b, c, d)
        if t == 0 then return b end
        if t == d then return b + c end
        t = t / (d / 2)
        if t < 1 then return c / 2 * math.pow(2, 10 * (t - 1)) + b - c * 0.0005 end
        t = t - 1
        return c / 2 * 1.0005 * (-math.pow(2, -10 * t) + 2) + b
    end,
}

local Animator = {}
Animator.Easing = Easing
Animator.activeAnimations = {}

function Animator.animate(startVal, endVal, duration, easingFunc, onUpdate, onComplete)
    local anim = {
        startVal = startVal,
        change = endVal - startVal,
        duration = duration,
        easingFunc = easingFunc or Easing.Linear,
        onUpdate = onUpdate,
        onComplete = onComplete,
        startTime = os.clock()
    }
    table.insert(Animator.activeAnimations, anim)
    return anim
end

function Animator.tick(currentTime)
    if #Animator.activeAnimations == 0 then return false end
    
    local completed = {}
    for i, anim in ipairs(Animator.activeAnimations) do
        local elapsed = currentTime - anim.startTime
        if elapsed >= anim.duration then
            if anim.onUpdate then anim.onUpdate(anim.startVal + anim.change) end
            if anim.onComplete then anim.onComplete() end
            table.insert(completed, i)
        else
            local val = anim.easingFunc(elapsed, anim.startVal, anim.change, anim.duration)
            if anim.onUpdate then anim.onUpdate(val) end
        end
    end
    
    for i = #completed, 1, -1 do
        table.remove(Animator.activeAnimations, completed[i])
    end
    
    return true
end

function Animator.hasActive()
    return #Animator.activeAnimations > 0
end

return Animator
