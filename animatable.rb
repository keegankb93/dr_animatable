module Animatable
  attr_accessor :current_animation, :animation_started_at

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    #
    # DSL to define animations
    def define_animations(tile_w: nil, tile_h: nil, &block)
      sheets = Sheets.build(tile_w, tile_h)

      sheets.instance_eval(&block)

      @animations = sheets.animations
    end

    #
    # Convenience method to get the animations
    def animations
      @animations
    end
  end

  #
  # Instance level convenience method for accessing the animations defined at the class level.
  def animations
    self.class.animations
  end

  #
  # Animation struct holds the animation data needed to play an animation
  Animation = Struct.new(:name, :path, :tile_w, :tile_h, :columns, :start, :frames, :start_frame, :hold_for, :repeat) do
    def self.create(name:,
                    path:,
                    tile_w:,
                    tile_h:,
                    columns:,
                    start:,
                    frames:,
                    start_frame: 0,
                    hold_for: 3,
                    repeat: true)
      row, col = start
      start_index = row * columns + col

      new(name, path, tile_w, tile_h, columns, start_index, frames, start_frame, hold_for, repeat)
    end

    #
    # Convenience method to get the number of frames in this animation.
    def frame_count
      frames
    end

    #
    # Gets the [row, col] of the i-th frame, wrapping at `columns`.
    # For example, with 4 columns, frame_cell(5) returns [1, 1].
    # index:  0      1      2      3
    #         [0,0]  [0,1]  [0,2]  [0,3]
    # index:  4      5      6      7
    #         [0,0]  [1,1]* [1,2]  [1,3]
    def frame_cell(i)
      index = start + i

      [index.idiv(columns), index % columns]
    end
  end

  #
  # Represents a collection of animations, organized by sheet or folder.
  Sheets = Struct.new(:tile_w, :tile_h, :animations) do
    def self.build(tile_w, tile_h)
      new(tile_w, tile_h, {})
    end

    #
    # Sheets allow you to define animations that are all in one sheet
    # For example, you may have a walk.png that holds all the frames in all directions for
    # the walking animation.You would then define the animations and their respective frames in the sheet block
    def sheet(path, columns:, tile_w: nil, tile_h: nil, &block)
      Sheet.new(path, tile_w || self.tile_w, tile_h || self.tile_h, columns, animations).instance_eval(&block)
    end

    #
    # Folders allow you to define animations that are split into individual files, one per animation.
    # The interface is similar to sheets except each animation is defined in a separate file.
    # The name of the animation is used to access the file in the folder (e.g. "walk.png" for the walking animation).
    #
    # I built this to make it easier to define animations that are split into individual files, one per animation.
    # and I typically name the files in a way that reflects the animation name (e.g. "walk.png" for the walking animation).
    # It may not suit your needs, so feel free to make changes or put up a PR :)
    def folder(dir, ext: :png, tile_w: nil, tile_h: nil, &block)
      Folder.new(dir, ext, tile_w || self.tile_w, tile_h || self.tile_h, animations).instance_eval(&block)
    end
  end

  #
  # Sheets allow you to define animations that are stored in a single image file.
  Sheet = Struct.new(:path, :tile_w, :tile_h, :columns, :animations) do
    def anim(name, start:, frames:, start_frame: 0, hold_for: 3, repeat: true)
      animations[name] = Animation.create(
        name: name,
        path: path,
        tile_w: tile_w,
        tile_h: tile_h,
        columns: columns,
        start: start,
        frames: frames,
        start_frame: start_frame,
        hold_for: hold_for,
        repeat: repeat
      )
    end
  end

  #
  # Folders allow you to define animations that are split into individual files, one per animation.
  Folder = Struct.new(:dir, :ext, :tile_w, :tile_h, :animations) do
    def anim(name, frames:, columns: nil, start: [0, 0], start_frame: 0, hold_for: 3, repeat: true)
      animations[name] = Animation.create(
        name: name,
        path: "#{dir}/#{name}.#{ext}",
        tile_w: tile_w,
        tile_h: tile_h,
        columns: columns || frames,
        start: start,
        frames: frames,
        start_frame: start_frame,
        hold_for: hold_for,
        repeat: repeat
      )
    end
  end

  #
  # Per instance modifiers for animations
  # e.g. modify(:walk_down, speed: 2)
  # Since animations are stored at the class level all instances share that same animation definition.
  # If we modify the animation directly, all instances will see the change, which could be kinda funny, but
  # not something we'd want in 99% of scenarios.
  def modifiers
    @modifiers ||= {}
  end

  #
  # Set one or more modifiers for an animation, e.g. modify(:walk_down, speed: 2)
  # Also accepts multiple animation names, e.g. modify(:walk_down, :walk_up, speed: 2)
  def modify_animations(*names, **changes)
    names.each { |name| (modifiers[name] ||= {}).merge!(changes) }
  end

  #
  # The main interface you use to play animations.
  # Examples:
  #   play_animation(:walk)
  #   play_animation(:idle)
  def play_animation(name)
    return if current_animation == name

    self.current_animation = name

    animation = animations.fetch(name)
    self.animation_started_at = Kernel.tick_count - (animation.start_frame * animation.hold_for)
  end

  #
  # Returns the sprite for the current animation frame.
  # This is what you will use to actually render your sprite
  # args.outputs.sprites << Object.animation_sprite
  def animation_sprite
    animation = animations.fetch(current_animation)

    # Hold last frame if animation is done
    index = animation_frame_index(animation) || (animation.frame_count - 1)
    row, col = animation.frame_cell(index)

    {
      x: x.to_i,
      y: y.to_i,
      w: w,
      h: h,
      path: animation.path,
      tile_x: col * animation.tile_w,
      tile_y: row * animation.tile_h,
      tile_w: animation.tile_w,
      tile_h: animation.tile_h,
      flip_horizontally: flip_animation?
    }
  end

  #
  # If no repeat animation_frame_index is nil, the animation is finished.
  def animation_finished?
    return false unless animation_started_at

    animation = animations.fetch(current_animation)

    return false if animation.repeat

    animation_frame_index(animation).nil?
  end

  #
  # Returns whether the sprite should be flipped horizontally.
  # Subclasses can override this to provide custom flipping behavior.
  def flip_animation?
    false
  end

  private

  #
  # Grab the value of the modifier for the given animation, or the default if not found.
  def modifier(name, key, default)
    mod = modifiers[name]

    (mod && mod[key]) || default
  end

  #
  # Returns the current frame index for the given animation.
  # https://docs.dragonruby.org/#/api/numeric?id=frame_index
  def animation_frame_index(animation)
    return 0 unless animation_started_at

    speed = modifier(animation.name, :speed, 1)
    hold = (animation.hold_for / speed).to_i
    hold = 1 if hold < 1
    animation_started_at.frame_index(animation.frame_count, hold, animation.repeat)
  end
end
