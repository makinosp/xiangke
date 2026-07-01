## TransitionConfig resource class.
## Configuration for scene transition animations.
class_name TransitionConfig
extends Resource

## Transition animation types.
enum AnimationType {
	FADE, ## Simple alpha fade between scenes.
	FADE_TO_BLACK, ## Fade to a solid color (default black), then fade in.
}

## Total transition duration in seconds. Must be > 0.0.
@export var duration: float = 0.5
## Color of the fade overlay. Default is black.
@export var fade_color: Color = Color(0, 0, 0, 1)
## Transition animation type.
@export var animation_type: AnimationType = AnimationType.FADE_TO_BLACK
## Hold time at full fade before loading the next scene.
@export var wait_time: float = 0.1
