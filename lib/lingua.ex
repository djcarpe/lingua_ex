defmodule Lingua do
  @moduledoc """
  Lingua wraps [Peter M. Stahl](https://github.com/pemistahl)'s [linuga-rs](https://github.com/pemistahl/lingua-rs) language detection library.
  This wrapper follows the lingua-rs API closely, so consult the [documentation](https://docs.rs/lingua/1.0.3/lingua/index.html) for more information.
  """

  @default_builder_option :all_languages
  @default_languages []
  @default_minimum_relative_distance 0.0
  @default_compute_language_confidence_values false

  @doc """
  Initialize the detector. Calling this is optional but it may come in handy in cases where you want lingua-rs to load
  the language corpora so that subsequent calls to `detect` are fast. The first time the detector is run it can take some time to load (~12 seconds on my Macbook Pro).

  ## Example

      iex> Lingua.init()
      :ok
  """
  defdelegate init(), to: Lingua.Nif

  @doc """
  Detect the language of the given input text. By default, all supported languages will be considered and
  the minimum relative distance is `0.0`.

  Returns the detected language, or a list of languages and their confidence values, or `:no_match` if the given text
  doesn't match a language.

  Options:

  * `builder_option:` - can be one of the following (defaults to `:all_languages`):
    * `:all_languages` - consider every supported language
    * `:all_spoken_languages` - consider only currently spoken languages
    * `:all_languages_with_arabic_script` - consider only languages written in Arabic script
    * `:all_languages_with_cyrillic_script` - consider only languages written in Cyrillic script
    * `:all_languages_with_devanagari_script` - consider only languages written in Devanagari script
    * `:all_languages_with_latin_script` - consider only languages written in Latin script
    * `:with_languages` - consider only the languages supplied in the `languages` option.
    * `:without_languages` - consider all languages except those supplied in the `languages` option. Two or more are required. (see below)

  * `languages:` - specify two or more languages to consider or to not consider depending on the `builder_option:` (defaults to `[]`). Accepts
  any combination of languages and ISO 639-1 or 639-3 codes, for example: `[:english, :ru, :lit]` to consider English, Russian and Lithuanian.

  * `with_minimum_relative_distance:` - specify the minimum relative distance (0.0 - 0.99) required for a language to be considered a match for the input.
  See the lingua-rs [documentation](https://docs.rs/lingua/1.0.3/lingua/struct.LanguageDetectorBuilder.html#method.with_minimum_relative_distance) for details. (defaults to `0.0`)

  * `compute_language_confidence_values:` - returns the full list of language matches for the input and their confidence values. (defaults to `false`)

  ## Example

      iex> Lingua.detect("this is definitely English")
      {:ok, :english}

      iex> Lingua.detect("וזה בעברית")
      {:ok, :hebrew}

      iex> Lingua.detect("państwowych", builder_option: :with_languages, languages: [:english, :russian, :polish])
      {:ok, :polish}

      iex> Lingua.detect("ѕидови", builder_option: :all_languages_with_cyrillic_script)
      {:ok, :macedonian}

      iex> Lingua.detect("כלב", builder_option: :with_languages, languages: [:english, :russian, :polish])
      {:ok, :no_match}

      iex> Lingua.detect("what in the world is this", builder_option: :with_languages, languages: [:english, :russian, :hebrew], compute_language_confidence_values: true)
      {:ok, [english: 1.0]}

  """
  def detect(text, options \\ []) do
    builder_option = Keyword.get(options, :builder_option, @default_builder_option)
    languages = Keyword.get(options, :languages, @default_languages)

    minimum_relative_distance =
      Keyword.get(options, :minimum_relative_distance, @default_minimum_relative_distance)

    compute_language_confidence_values =
      Keyword.get(
        options,
        :compute_language_confidence_values,
        @default_compute_language_confidence_values
      )

    if compute_language_confidence_values,
      do:
        Lingua.Nif.compute_language_confidence_values(
          text,
          builder_option,
          languages,
          minimum_relative_distance
        ),
      else:
        Lingua.Nif.detect_language_of(text, builder_option, languages, minimum_relative_distance)
  end

  @doc """
  Like `detect`, but returns the result value or raises an error.
  """
  def detect!(text, options \\ []) do
    case detect(text, options) do
      {:ok, value} -> value
      {:error, error} -> raise error
    end
  end

  @doc """
  Get the list of supported languages.

  ## Example

      iex> Lingua.all_languages()
      [:armenian, :basque, :slovak, :vietnamese, :polish, :icelandic, :bulgarian, ...]
  """
  defdelegate all_languages(), to: Lingua.Nif

  @doc """
  Get the list of supported spoken languages.

  ## Example

      iex> Lingua.all_spoken_languages()
      [:yoruba, :danish, :finnish, :punjabi, :italian, :french, :ganda, :georgian, ...]
  """
  defdelegate all_spoken_languages(), to: Lingua.Nif

  @doc """
  Get the list of supported languages using Arabic script.

  ## Example

      iex> Lingua.all_with_arabic_script()
      [:arabic, :persian, :urdu]
  """
  defdelegate all_with_arabic_script(), to: Lingua.Nif

  @doc """
  Get the list of supported languages using Cyrillic script.

  ## Example

      iex> Lingua.all_with_cyrillic_script()
      [:ukrainian, :kazakh, :russian, :belarusian, :macedonian, :bulgarian, :mongolian, :serbian]
  """
  defdelegate all_with_cyrillic_script(), to: Lingua.Nif

  @doc """
  Get the list of supported languages using Devanagari script.

  ## Example

      iex> Lingua.all_with_devanagari_script()
      [:marathi, :hindi]
  """
  defdelegate all_with_devanagari_script(), to: Lingua.Nif

  @doc """
  Get the list of supported languages using Latin script.

  ## Example

      iex> Lingua.all_with_latin_script()
      [:afrikaans, :finnish, :french, :icelandic, :portuguese, :estonian, ...]
  """
  defdelegate all_with_latin_script(), to: Lingua.Nif

  @doc """
  Get the language for the given ISO 639-1 language code.

  ## Example

      iex> Lingua.language_for_iso_code_639_1(:en)
      {:ok, :english}
      iex> Lingua.language_for_iso_code_639_1(:er)
      {:error, :unrecognized_iso_code}
  """
  defdelegate language_for_iso_code_639_1(code), to: Lingua.Nif

  @doc """
  Get the language for the given ISO 639-3 language code.

  ## Example

      iex> Lingua.language_for_iso_code_639_3(:eng)
      {:ok, :english}
      iex> Lingua.language_for_iso_code_639_3(:enr)
      {:error, :unrecognized_iso_code}
  """
  defdelegate language_for_iso_code_639_3(code), to: Lingua.Nif

  @doc """
  Get the language for the given ISO 639-1 or 639-3 language code.

  ## Example

      iex> Lingua.language_for_iso_code(:en)
      {:ok, :english}
      iex> Lingua.language_for_iso_code(:eng)
      {:ok, :english}
      iex> Lingua.language_for_iso_code(:mop)
      {:error, :unrecognized_iso_code}
  """
  defdelegate language_for_iso_code(code), to: Lingua.Nif

  @doc """
  Get the ISO 639-1 language code for the given language.

  ## Example

      iex> Lingua.iso_code_639_1_for_language(:english)
      {:ok, :en}
      iex> Lingua.iso_code_639_1_for_language(:nope)
      {:error, :unrecognized_language}
  """
  defdelegate iso_code_639_1_for_language(language), to: Lingua.Nif

  @doc """
  Get the ISO 639-3 language code for the given language.

  ## Example

      iex> Lingua.iso_code_639_3_for_language(:english)
      {:ok, :eng}
      iex> Lingua.iso_code_639_1_for_language(:nope)
      {:error, :unrecognized_language}
  """
  defdelegate iso_code_639_3_for_language(language), to: Lingua.Nif
end
