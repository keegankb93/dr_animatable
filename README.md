# dr_animatable
Animation module to help make managine spritesheet animations easier.

> [!NOTE]
> This is a more opinionated take on animation and how I tend to view animating sprites. This may or may not work for you, but if you find you like using this module, but need more from it, feel free to make a PR or raise an issue!


<img width="800" height="497" alt="ScreenRecording2026-06-04at7 56 01PM-ezgif com-video-to-gif-converter" src="https://github.com/user-attachments/assets/2c161269-f3ce-41ba-8fae-610f149e6003" />

## TODO

- on_animation_end/timings

## Usage

There are two ways you can define your animations `folders` or `sheet`

```ruby
class Player
  include Animatable

  define_animations(tile_w: 16, tile_h: 16) do
    folder('sprites/characters/player') do
      anim :idle_up,   frames: 1, hold_for: 1
      anim :idle_down, frames: 1, hold_for: 1
      anim :idle_side, frames: 1, hold_for: 1
      anim :walk_up,   frames: 4, hold_for: 20, start_frame: 1
      anim :walk_down, frames: 4, hold_for: 20, start_frame: 1
      # anim :walk_side, frames: 4, hold_for: 20, start_frame: 1
    end

    sheet('sprites/characters/player/walk_side.png', columns: 4) do
      anim :walk_side, start: [0, 0], frames: 4, hold_for: 20, start_frame: 1
    end
  end

end
```

Mainly, the spritesheets I come across come in two different forms. 

- 1 animation per file (walk_down, walk_up etc. in separate files)
- Multiple animations per file (all walk animations in 1 file)

### Folder (1 sheet per animation)

```ruby
  define_animations(tile_w: 16, tile_h: 16) do
    folder('sprites/characters/player') do
      anim :idle_up,   frames: 1, hold_for: 1
      anim :idle_down, frames: 1, hold_for: 1
      anim :idle_side, frames: 1, hold_for: 1
      anim :walk_up,   frames: 4, hold_for: 20, start_frame: 1
      anim :walk_down, frames: 4, hold_for: 20, start_frame: 1
      anim :walk_side, frames: 4, hold_for: 20, start_frame: 1
    end
  end
```

```ruby 
def folder(directory, ext:, tile_w:, tile_h:); end
```

`directory` - The directory your sheets are located in

`ext` - The extension your sheets are (.png, .jpeg, etc.)

`tile_w` - Tile width override

`tile_h` - Tile height override


```ruby 
def anim(name, frames:, columns: nil, start: [0, 0], start_frame: 0, hold_for: 3, repeat: true); end
```

`name` - Animation name

> [!IMPORTANT]
> Animation name MUST match the file name (this is how we look it up). It is also how you reference the animation when you want to play the animation.

`frames` - the number of frames the animation is

`columns` - the number of columns in the spritesheet

`start` - The first frame of the animation, this is the row/col [0, 0] represents the top-left and moves left-to-right as most spritesheets

`start_frame` - The frame to start on (use this to start directly into a walking animation etc. if the animation has a neutral frame)

`hold_for` - How long to hold each animation for (this speeds or slows the animation speed)

`repeat` - Loop the animation

### Sheet (multiple animations per sheet)

```ruby
  define_animations(tile_w: 16, tile_h: 16) do
    sheet('sprites/characters/player/walk_side.png', columns: 4) do
      anim :walk_side, start: [0, 0], frames: 4, hold_for: 20, start_frame: 1
    end
  end
```


```ruby 
def anim(name, start:, frames:, start_frame: 0, hold_for: 3, repeat: true); end
```

`name` - Animation name

`start` - The first frame of the animation, this is the row/col [0, 0] represents the top-left and moves left-to-right as most spritesheets

`frames` - the number of frames the animation is

`start_frame` - The frame to start on (use this to start directly into a walking animation etc. if the animation has a neutral frame)

`hold_for` - How long to hold each animation for (this speeds or slows the animation speed)

`repeat` - Loop the animation

### Flipping an animation

Whatever logic you need to determine whether your animation should be flipped_horizontally should evaluate to true/false using this method.
This is defaulted to false in the module.

```ruby
  def flip_animation?
    true #logic to determine flip
  end
```


### Playing an animation

```ruby
def play_animation(name); end
```

```ruby
facing = :down

play_animation(:"walk_#{facing}")
```

### Modifiers

This module stores your animations when the class is loaded and saves those animations as a class ivar. The downside to this is that if you have 30 dogs and you want to change the animation speed for 1 of those dogs, it will change all dogs to that animation speed. To combat this, modifiers allow you to choose animation(s) and change a specific property of that animation for that instance. If that property is found, it will use it or just continue with the defaults.

> [!NOTE]
> Only animation speed is modifiable at this time

```ruby
  modify_animations(:idle_up, speed: 3)
  modify_animations(:idle_up, :idle_down, :idle_side, speed: 0)
```

### Animation state

```ruby
def animation_finished?;end
```

If you set your animation to `repeat: false` this will return true when your animation is done playing. The animation will hold its last frame.

