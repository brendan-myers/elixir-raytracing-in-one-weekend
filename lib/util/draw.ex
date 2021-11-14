defmodule Draw do

  alias Scenic.Graph

  require Camera
  require Logger
  require RayColour
  import Scenic.Primitives
  require Utilities
  require Vector

  def draw(params) do
    aspect_ratio = params.draw.width / params.draw.height

    h = :math.tan(
      (params.camera.vfov |> Utilities.degrees_to_radians()) / 2
    )

    viewport_height = 2 * h
    viewport_width = aspect_ratio * viewport_height

    focus_dist = params.camera.look_from
    |> Vector.sub(params.camera.look_at)
    |> Vector.vec3_length()

    scene_params = %{
      width:      params.draw.width,
      height:     params.draw.height,
      resolution: params.draw.resolution,
      objects:    params.objects,
      samples:    params.draw.samples,
      max_depth:  params.draw.max_depth,
    }

    camera_params = %{
      origin:           params.camera.look_from,
      look_at:          params.camera.look_at,
      viewport_width:   viewport_width,
      viewport_height:  viewport_height,
      focal_length:     params.camera.focal_length,
      aperture:         params.camera.aperture,
      focus_dist:       focus_dist,
      v_up:             params.camera.v_up,
      position:         params.camera.position, # unused
    }

    camera = Camera.camera(camera_params)

    draw(Graph.build(), scene_params, camera)
  end

  def draw(graph, params, camera) do
    pixel_sz = params.width / params.resolution

    loop_params = Map.put(params, :pixel_sz, pixel_sz)

    i = params.width  / pixel_sz
    j = params.height / pixel_sz

    draw_loop_j(graph, loop_params, camera, i, j)
  end
  def draw_loop_j(graph, params, camera, i, j) do
    case {j} do
      {x} when x<0 ->
        graph
      {_} ->
        Logger.info("j: #{inspect(j)}")

        updated_graph = draw_loop_i(graph, params, camera, i, j)
        draw_loop_j(updated_graph, params, camera, i, j-1)
    end
  end
  def draw_loop_i(graph, params, camera, i, j) do
    case {i} do
      {x} when x<0 ->
        graph
      {_} ->
        pixel_colour = sample_pixel(
          camera,
          i,
          j,
          params
        ) |> Colour.colour

        # flip the image the right way up!
        flip_j = params.height / params.pixel_sz - j

        updated_graph = draw_pixel(graph, i, flip_j, pixel_colour, params.pixel_sz, params.samples)

        draw_loop_i(updated_graph, params, camera, i-1, j)
    end
  end

  def sample_pixel(camera, i, j, params) do
    sample_pixel(camera, i, j, params, Vector.vec3(0, 0, 0), params.samples)
  end
  def sample_pixel(camera, i, j, params, colour, samples) do
    case samples do
      x when x<=0 ->
        colour
      _ ->
        u = (i + :rand.uniform) / (params.width  / params.pixel_sz)
        v = (j + :rand.uniform) / (params.height / params.pixel_sz)

        r = Camera.camera_get_ray(camera, u, v)
        pixel_colour = RayColour.ray_colour(r, params.objects, params.max_depth)
        |> Vector.add(colour)

        sample_pixel(camera, i, j, params, pixel_colour, samples-1)
    end
  end

  def draw_pixel(graph, x, y, colour, pixel_sz, samples) do
    scale = 1 / samples

    r_unscaled = :math.sqrt(colour.r * scale) |> Utilities.clamp(0, 1)
    g_unscaled = :math.sqrt(colour.g * scale) |> Utilities.clamp(0, 1)
    b_unscaled = :math.sqrt(colour.b * scale) |> Utilities.clamp(0, 1)

    r = r_unscaled * 255 |> trunc
    g = g_unscaled * 255 |> trunc
    b = b_unscaled * 255 |> trunc

    x_off = x * pixel_sz
    y_off = y * pixel_sz

    graph |> rect({pixel_sz, pixel_sz}, fill: {r, g, b}, translate: {x_off, y_off})
  end
end
