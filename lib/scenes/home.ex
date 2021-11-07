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

    pixel_n = 50 # number of pixels horizontally

    aspect_ratio = 1 #16.0 / 9.0

    # this would change based on aspect ratio
    viewport_height = 2
    viewport_width = aspect_ratio * viewport_height
    focal_length = 1

    origin = vec3(0, 0, 0)
    horizontal = vec3(viewport_width, 0, 0)
    vertical = vec3(0, viewport_height, 0)
    lower_left_corner = origin
      |> vec_sub(vec_div(horizontal, 2))
      |> vec_sub(vec_div(vertical, 2))
      |> vec_sub(vec3(0, 0, focal_length))

    # Logger.info("origin: #{inspect(origin)}")
    # Logger.info("horizontal: #{inspect(horizontal)}")
    # Logger.info("vertical: #{inspect(vertical)}")
    # Logger.info("lower_left_corner: #{inspect(lower_left_corner)}")

    # graph = draw_test(Graph.build(), width, height, pixel_n)
    graph = draw(Graph.build(), width, height, pixel_n,
      origin, horizontal, vertical, lower_left_corner)

    {:ok, graph, push: graph}
  end

  def draw_test(graph, width, height, pixel_n) do
    pixel_sz = width / pixel_n
    draw_test(graph, width, height, pixel_n, pixel_sz, pixel_n*pixel_n)
  end
  def draw_test(graph, width, height, pixel_n, pixel_sz, i) do
    case {i} do
      {x} when x<0 ->
        graph
      {_} ->
        x = rem(i, pixel_n)
        y = div(i, pixel_n)

        x_off = div( rem(i, pixel_n)*width, pixel_n)
        y_off = div( div(i, pixel_n)*height, pixel_n)

        r = trunc((x/pixel_n) * 255)
        g = trunc((y/pixel_n) * 255)
        b = trunc(0.25 * 255)

        # Logger.info("x:#{inspect(x)}, y:#{inspect(y)} = r:#{inspect(r)}, g:#{inspect(g)}, b:#{inspect(b)}")

        updated_graph = graph
        |> rect({pixel_sz, pixel_sz}, fill: {r, g, b}, translate: {x_off, y_off})

        draw_test(updated_graph, width, height, pixel_n, pixel_sz, i-1)
    end
  end

  def draw(graph, width, height, pixel_n,
    origin, horizontal, vertical, lower_left_corner) do

    pixel_sz = width / pixel_n

    # Logger.info("pixel_sz: #{inspect(pixel_sz)}")
    # Logger.info("width/pixel_sz: #{inspect(width/pixel_sz)}")

    draw_loop_j(graph, width, height, pixel_sz,
      origin, horizontal, vertical, lower_left_corner, width/pixel_sz, height/pixel_sz)
  end
  def draw_loop_j(graph, width, height, pixel_sz,
    origin, horizontal, vertical, lower_left_corner, i, j) do

    case {j} do
      {x} when x<0 ->
        graph
      {_} ->
        # Logger.info("j: #{inspect(j)}")

        updated_graph = draw_loop_i(graph, width, height, pixel_sz,
          origin, horizontal, vertical, lower_left_corner, i, j)
        draw_loop_j(updated_graph, width, height, pixel_sz,
          origin, horizontal, vertical, lower_left_corner, i, j-1)
    end
  end
  def draw_loop_i(graph, width, height, pixel_sz,
    origin, horizontal, vertical, lower_left_corner, i, j) do

    case {i} do
      {x} when x<0 ->
        graph
      {_} ->
        # Logger.info("  i: #{inspect(i)}")

        u = i / (width/pixel_sz)
        v = j / (height/pixel_sz)

        direction = lower_left_corner
        |> vec_add(vec_mul(horizontal, u))
        |> vec_add(vec_mul(vertical, v))
        |> vec_sub(origin)

        r = ray(origin, direction)

        updated_graph = draw_pixel(graph, i, j, ray_colour(r), pixel_sz)

        draw_loop_i(updated_graph, width, height, pixel_sz,
          origin, horizontal, vertical, lower_left_corner, i-1, j)
    end
  end

  def draw_pixel(graph, x, y, colour, pixel_sz) do
    # Logger.info("#{inspect(colour)}")

    r = trunc(colour.r * 255)
    g = trunc(colour.g * 255)
    b = trunc(colour.b * 255)

    x_off = x * pixel_sz
    y_off = y * pixel_sz

    # Logger.info("x, y, x_off, y_off, colour, sz; #{inspect({x, y, x_off, y_off, {r, g, b}, pixel_sz})}")

    graph |> rect({pixel_sz, pixel_sz}, fill: {r, g, b}, translate: {x_off, y_off})
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
  def ray_colour(ray) do
    case hit(:sphere, {vec3(0, 0, -1), 0.5}, ray, -1, 1) do
      {:hit, rec} ->
        colour(rec.normal.x+1, rec.normal.y+1, rec.normal.z+1)
        |> vec_mul(0.5)
        |> colour
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
        |> colour
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


        rec = %{
          t: t,
          p: p,
          normal: normal
        }

        {:hit, rec}
      end
    end
  end

end
