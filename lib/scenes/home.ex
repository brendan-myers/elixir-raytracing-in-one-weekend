defmodule Raytracer.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  # import Scenic.Components

  def init(_, opts) do
    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])

    offsets = {0, 0, 0}

    graph = draw(width, height, offsets)

    state = %{
      graph: graph,
      offsets: offsets,
      width: width,
      height: height
    }

    {:ok, state, push: graph}
  end

  def handle_input(event, _context, state) do
    offset_n = 0.1

    case event do
      {:key, {key_pressed, :press, _}} ->
        {x, y, z} = state.offsets

        left = if key_pressed == "left", do: -offset_n, else: 0
        right = if key_pressed == "right", do: offset_n, else: 0
        forward = if key_pressed == "up", do: -offset_n, else: 0
        backward = if key_pressed == "down", do: offset_n, else: 0
        up = if key_pressed == "[", do: offset_n, else: 0
        down = if key_pressed == "]", do: -offset_n, else: 0

        offsets = {
          x + left + right,
          y + up + down,
          z + backward + forward
        }
        graph = draw(state.width, state.height, offsets)

        new_state = %{
          graph: graph,
          offsets: offsets,
          width: state.width,
          height: state.height
        }

        {:noreply, new_state, push: graph}
      _ ->
        {:noreply, state}
    end
  end

  def draw(width, height, offsets) do
    # objects in the scene
    hit_list = [
      %{type: :sphere, params: {vec3(0, 0, -1), 0.5}},
      %{type: :sphere, params: {vec3(0, -100.5, -1), 100}},
    ]

    pixel_n = 100 # number of pixels horizontally/vertically, ie resolution

    three_d = false

    aspect_ratio = width / height #1 #16.0 / 9.0
    # this would change based on aspect ratio
    viewport_height = 2
    viewport_width = aspect_ratio * viewport_height
    focal_length = 1
    {x, y, z} = offsets
    eye_spacing = 0.05

    if three_d do
      camera_1 = camera(vec3(-eye_spacing+x, 0+y, 0+z), viewport_width, viewport_height, focal_length)
      camera_2 = camera(vec3(eye_spacing+x, 0+y, 0+z), viewport_width, viewport_height, focal_length)

      # graph =
      draw(Graph.build(), width/2, height, pixel_n, 0, camera_1, hit_list)
        |> draw(width/2, height, pixel_n, width/2, camera_2, hit_list)

      # {:ok, graph, push: graph}
    else
      camera = camera(vec3(0+x, 0+y, 0+z), viewport_width, viewport_height, focal_length)

      # graph =
      draw(Graph.build(), width, height, pixel_n, 0, camera, hit_list)

      # {:ok, %{graph: graph, offsets: offsets}, push: graph}
    end
  end

  def draw(graph, width, height, pixel_n, offset, camera, hit_list) do
    pixel_sz = width / pixel_n

    draw_loop_j(graph, width, height, pixel_sz, offset, camera, hit_list, width/pixel_sz, height/pixel_sz)
  end
  def draw_loop_j(graph, width, height, pixel_sz, offset, camera, hit_list, i, j) do

    case {j} do
      {x} when x<0 ->
        graph
      {_} ->
        # Logger.info("j: #{inspect(j)}")

        updated_graph = draw_loop_i(graph, width, height, pixel_sz, offset, camera, hit_list, i, j)
        draw_loop_j(updated_graph, width, height, pixel_sz, offset, camera, hit_list, i, j-1)
    end
  end
  def draw_loop_i(graph, width, height, pixel_sz, offset, camera, hit_list, i, j) do

    case {i} do
      {x} when x<0 ->
        graph
      {_} ->
        samples = 5

        pixel_colour = sample_pixel(camera, i, j, width, height, pixel_sz, hit_list, samples)
        |> colour

        # flip the image the right way up!
        flip_j = height/pixel_sz - j

        updated_graph = draw_pixel(graph, i, flip_j, pixel_colour, pixel_sz, offset, samples)

        draw_loop_i(updated_graph, width, height, pixel_sz, offset, camera, hit_list, i-1, j)
    end
  end

  def draw_pixel(graph, x, y, colour, pixel_sz, offset, samples) do
    scale = 1 / samples

    r_unscaled = :math.sqrt(colour.r * scale) |> clamp(0, 1)
    g_unscaled = :math.sqrt(colour.g * scale) |> clamp(0, 1)
    b_unscaled = :math.sqrt(colour.b * scale) |> clamp(0, 1)

    r = r_unscaled * 255 |> trunc
    g = g_unscaled * 255 |> trunc
    b = b_unscaled * 255 |> trunc

    x_off = x * pixel_sz + offset
    y_off = y * pixel_sz

    graph |> rect({pixel_sz, pixel_sz}, fill: {r, g, b}, translate: {x_off, y_off})
  end

  def sample_pixel(camera, i, j, width, height, pixel_sz, hit_list, samples) do
    sample_pixel(camera, i, j, width, height, pixel_sz, hit_list, vec3(0, 0, 0), samples)
  end

  def sample_pixel(camera, i, j, width, height, pixel_sz, hit_list, colour, samples) do
    case samples do
      x when x<=0 ->
        colour
      _ ->
        u = (i + :rand.uniform) / (width/pixel_sz)
        v = (j + :rand.uniform) / (height/pixel_sz)

        r = camera_get_ray(camera, u, v)
        pixel_colour = ray_colour(r, hit_list, 5)
        |> vec_add(colour)

        sample_pixel(camera, i, j, width, height, pixel_sz, hit_list, pixel_colour, samples-1)
    end
  end

  ###############################
  #
  # Vector

  def vec3(x, y, z) do
    %{
      x: x,
      y: y,
      z: z
    }
  end
  def vec3_random() do
    %{
      x: :rand.uniform,
      y: :rand.uniform,
      z: :rand.uniform,
    }
  end
  def vec3_random(min, max) do
    %{
      x: random(min, max),
      y: random(min, max),
      z: random(min, max),
    }
  end
  def vec_add(v1, v2) do
    %{
      x: v1.x + v2.x,
      y: v1.y + v2.y,
      z: v1.z + v2.z
    }
  end
  def vec_sub(v1, v2) do
    %{
      x: v1.x - v2.x,
      y: v1.y - v2.y,
      z: v1.z - v2.z
    }
  end
  def vec_mul(v, t) do
    %{
      x: v.x * t,
      y: v.y * t,
      z: v.z * t
    }
  end
  def vec_div(v, t) do
    vec_mul(v, 1/t)
  end
  def vec_length(v) do
    :math.sqrt(vec_length_squared(v))
  end
  def vec_length_squared(v) do
    v.x*v.x + v.y*v.y + v.z*v.z
  end

  ### Helpers

  def dot(v1, v2) do
    v1.x*v2.x + v1.y*v2.y + v1.z*v2.z
  end
  def cross(v1, v2) do
    %{
      x: v1.y*v2.z - v1.z*v2.y,
      y: v1.z*v2.x - v1.x*v2.z,
      z: v1.x*v2.y - v1.y*v2.x
    }
  end
  def unit_vector(v) do
    vec_div(v, vec_length(v))
  end
  def random_in_unit_sphere() do
    v = vec3_random()

    if vec_length_squared(v) < 1 do
      v
    else
      random_in_unit_sphere()
    end
  end
  def random_unit_vector() do
    random_in_unit_sphere() |> unit_vector()
  end


  ###############################
  #
  # Colour

  def colour(r, g, b) do
    vec3(r, g, b)
  end
  def colour(v) do
    %{
      r: v.x,
      g: v.y,
      b: v.z
    }
  end


  ###############################
  #
  # Camera

  def camera(origin, viewport_width, viewport_height, focal_length) do
    horizontal = vec3(viewport_width, 0, 0)
    vertical = vec3(0, viewport_height, 0)
    lower_left_corner = origin
      |> vec_sub(vec_div(horizontal, 2))
      |> vec_sub(vec_div(vertical, 2))
      |> vec_sub(vec3(0, 0, focal_length))

    %{
      origin: origin,
      horizontal: horizontal,
      vertical: vertical,
      lower_left_corner: lower_left_corner
    }
  end

  def camera_get_ray(camera, u, v) do
    direction = camera.lower_left_corner
    |> vec_add(vec_mul(camera.horizontal, u))
    |> vec_add(vec_mul(camera.vertical, v))
    |> vec_sub(camera.origin)

    ray(camera.origin, direction)
  end

  ###############################
  #
  # Ray

  def ray(origin, direction) do
    %{
      origin: origin,
      direction: direction
    }
  end
  def ray_at(ray, t) do
    vec_mul(ray.direction, t)
    |> vec_add(ray.origin)
  end
  def ray_colour(_ray, _hit_list, 0) do
    colour(0, 0, 0)
  end
  def ray_colour(ray, hit_list, depth) do
    case hittable_list_hit(hit_list, ray, 0.001, 999999) do
      {:hit, rec} ->
        target = rec.p |> vec_add(rec.normal) |> vec_add(random_unit_vector())

        rec.p
        |> ray(target |> vec_sub(rec.p))
        |> ray_colour(hit_list, depth-1)
        |> vec_mul(0.5)

      _ ->
        unit_direction = unit_vector(ray.direction)
        t = 0.5 * (unit_direction.y + 1)

        colour_1 = colour(1.0, 1.0, 1.0)
        colour_2 = colour(0.5, 0.7, 1.0)

        colour_1
        |> vec_mul((1-t))
        |> vec_add(
          colour_2
          |> vec_mul(t))
    end
  end


  ###############################
  #
  # Hit Record

  def set_face_normal(outward_normal, ray) do
    front_face = ray.direction |> dot(outward_normal)

    if front_face < 0 do
      outward_normal
    else
      outward_normal |> vec_mul(-1)
    end
  end

  def hit(:sphere, sphere, ray, t_min, t_max) do
    {center, radius} = sphere

    oc = ray.origin |> vec_sub(center)
    a = ray.direction |> vec_length_squared()
    half_b = oc |> dot(ray.direction)
    c = (oc |> vec_length_squared()) - radius*radius
    disciminant = half_b*half_b - a*c

    if disciminant < 0 do
      {:miss}
    else

      # find the nearest root that lies in the acceptable range
      sqrtd = :math.sqrt(disciminant)
      root = (-half_b - sqrtd) / a

      # todo, there must be a way to not have ugly nested ifs
      root_2 = (-half_b + sqrtd) / a

      if (root < t_min or root > t_max) and
        (root_2 < t_min || t_max < root_2) do
          {:miss}
      else
        t = root
        p = ray |> ray_at(t)
        normal = p
        |> vec_sub(center)
        |> vec_div(radius)
        |> set_face_normal(ray)


        hit_record = %{
          t: t,
          p: p,
          normal: normal
        }

        {:hit, hit_record}
      end
    end
  end


  ###############################
  #
  # Hittable list
  def hittable_list_hit(objects, ray, t_min, t_max) do
    hittable_list_hit(objects, ray, t_min, t_max, nil)
  end
  def hittable_list_hit([object|objects], ray, t_min, t_closest, hit_record) do
    rec = hit(:sphere, object.params, ray, t_min, t_closest)

    case rec do
      {:hit, details} ->
        hittable_list_hit(objects, ray, t_min, details.t, rec)
      _ ->
        hittable_list_hit(objects, ray, t_min, t_closest, hit_record)
    end


  end
  def hittable_list_hit([], _ray, _t_min, _t_closest, hit_record) do
    hit_record
  end


  ###############################
  #
  # Utilities

  def degrees_to_radians(degrees) do
    degrees * :math.pi / 180.0
  end

  def random(min, max) do
    min + (max-min) * :rand.uniform
  end

  def clamp(x, min, max) do
    case x do
      x when x < min ->
        min
      x when x > max ->
        max
      _ ->
        x
    end
  end

end
