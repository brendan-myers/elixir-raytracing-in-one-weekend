defmodule Raytracer.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.ViewPort

  def init(_, opts) do
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])

    # What's in the scene
    scene_objects = [
      %{
        # left
        type: :sphere,
        params: {Vector.vec3(-1, 0, -1), 0.5},
        material: Material.dielectric(1.5)
      },
      %{
        # left
        type: :sphere,
        params: {Vector.vec3(-1, 0, -1), -0.45},
        material: Material.dielectric(1.5)
      },
      %{
        # center
        type: :sphere,
        params: {Vector.vec3(0, 0, -1), 0.49},
        material: Material.metal(Colour.colour(0.1, 0.2, 0.5), 1)
      },
      %{
        # center
        type: :sphere,
        params: {Vector.vec3(0, 0, -1), 0.5},
        material: Material.dielectric(1.5)
      },
      %{
        # right
        type: :sphere,
        params: {Vector.vec3(1, 0, -1), 0.5},
        material: Material.metal(Colour.colour(0.1, 0.2, 0.5), 0)
      },
      %{
        # ground
        type: :sphere,
        params: {Vector.vec3(0, -100.5, -1), 100},
        material: Material.metal(Colour.colour(0.5, 0.5, 0.5), 0.1)
      }
    ]


    params = %{
      objects:        scene_objects,
      draw: %{
        width:        width,
        height:       height,
        resolution:   200, # x resolution. y resolution will scale automatically.
        samples:      5, # number of samples to take per pixel
        max_depth:    50,
      },
      camera: %{
        look_from:    Vector.vec3(-5, 1, 2),
        look_at:      Vector.vec3(0, 0, -1),
        v_up:         Vector.vec3(0, 1, 0),
        focal_length: 1,
        aperture:     1,
        vfov:         30,
        position: %{ # unused
          pitch:      0,
          yaw:        0,
          roll:       0,
        }
      },
      offsets: %{ # unused
        x:    0,
        y:    0,
        z:    0,
        fov:  0,
      },
    }

    graph = Draw.draw(params)

    state = %{
      graph: graph,
      params: params,
      width: width,
      height: height
    }

    {:ok, state, push: graph}
  end
end
