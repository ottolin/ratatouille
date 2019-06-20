defmodule Ratatouille.Renderer.Text do
  @moduledoc """
  Primitives for rendering text
  """

  alias ExTermbox.{Cell, Position}
  alias Ratatouille.Renderer.{Canvas, Cells, Element}

  def render(canvas, %Position{} = position, text, attrs \\ %{})
      when is_binary(text) do
    template = template_cell(attrs)
    cell_generator = Cells.generator(position, :horizontal, template)

    cells =
      text
      |> String.graphemes()
      #|> Enum.with_index()
      |> process_text
      |> Enum.map(cell_generator)

    Canvas.merge_cells(canvas, cells)
  end

  def string_width(str) do
    str |> String.graphemes |> Enum.map(&grapheme_width/1) |> Enum.sum
  end

  def grapheme_width(<<g::utf8>>) do
    if g >= 0x1100 &&
       (g <= 0x115f || g == 0x2329 || g == 0x232a ||
            (g >= 0x2e80 && g <= 0xa4cf && g != 0x303f) ||
            (g >= 0xac00 && g <= 0xd7a3) ||
            (g >= 0xf900 && g <= 0xfaff) ||
            (g >= 0xfe30 && g <= 0xfe6f) ||
            (g >= 0xff00 && g <= 0xff60) ||
            (g >= 0xffe0 && g <= 0xffe6) ||
            (g >= 0x20000 && g <= 0x2fffd) ||
            (g >= 0x30000 && g <= 0x3fffd)) do
      2
    else
      1
    end
  end

  def process_text(graphemes) do
    {rv, _} =
      graphemes
      |> Enum.reduce({[], 0},
           fn g, {g_list, offset} ->
             #ch_len = if :unicode.bin_is_7bit(g), do: 1, else: 2
             ch_len = g |> grapheme_width
             {[{g, offset}|g_list], offset + ch_len}
           end)
    rv |> Enum.reverse
  end

  def render_group(canvas, text_elements, attrs \\ %{}) do
    rendered_canvas =
      Enum.reduce(text_elements, canvas, fn el, canvas ->
        element = %Element{el | attributes: Map.merge(attrs, el.attributes)}
        render_group_member(canvas, element)
      end)

    %Canvas{rendered_canvas | render_box: canvas.render_box}
  end

  defp render_group_member(
         canvas,
         %Element{tag: :text, attributes: attrs, children: []}
       ) do
    text = attrs[:content] || ""

    canvas
    |> render(canvas.render_box.top_left, text, attrs)
    |> Canvas.translate(string_width(text), 0)
  end

  defp template_cell(attrs) do
    %Cell{
      bg: Cells.background(attrs),
      fg: Cells.foreground(attrs),
      ch: nil,
      position: nil
    }
  end
end
