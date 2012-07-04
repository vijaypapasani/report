require 'fileutils'

class Report
  class Pdf
    DEFAULT_FONT = {
      :normal      => File.expand_path('../pdf/DejaVuSansMono.ttf', __FILE__),
      :italic      => File.expand_path('../pdf/DejaVuSansMono-Oblique.ttf', __FILE__),
      :bold        => File.expand_path('../pdf/DejaVuSansMono-Bold.ttf', __FILE__),
      :bold_italic => File.expand_path('../pdf/DejaVuSansMono-BoldOblique.ttf', __FILE__),
    }
    DEFAULT_DOCUMENT = {
      :top_margin => 118,
      :right_margin => 36,
      :bottom_margin => 72,
      :left_margin => 36,
      :page_layout => :landscape,
    }
    DEFAULT_HEAD = {}
    DEFAULT_BODY = {
      :width => (10*72),
      :header => true
    }
    DEFAULT_NUMBER_PAGES = [
      'Page <page> of <total>',
      {:at => [648, -2], :width => 100, :size => 10}
    ]

    include Utils

    attr_reader :report

    def initialize(report)
      @report = report
    end

    def path
      return @path if defined?(@path)
      require 'prawn'
      tmp_path = tmp_path(:extname => '.pdf')
      Prawn::Document.generate(tmp_path, document) do |pdf|
        
        pdf.font_families.update(font_name => font)
        pdf.font font_name

        report.tables.each do |table|
          t = []
          table.each_head(report) { |row| t << row.to_a }
          pdf.table(t, head) if t.length > 0

          pdf.move_down 20
          pdf.text table.name, :style => :bold
          pdf.move_down 10

          t = []
          table.each_body(report) { |row| t << row.to_a }
          pdf.table(t, body) if t.length > 0
        end

        pdf.number_pages(*number_pages)
      end
      
      if stamp
        raise "#{stamp} not readable or does not exist" unless File.readable?(stamp)
        require 'posix/spawn'
        POSIX::Spawn::Child.new 'pdftk', tmp_path, 'stamp', stamp, 'output', "#{tmp_path}.stamped"
        FileUtils.mv "#{tmp_path}.stamped", tmp_path
      end

      @path = tmp_path
    end

    private

    def font_name
      'MainFont'
    end
    
    def font
      DEFAULT_FONT.merge report.pdf_format.fetch(:font, {})
    end
    
    def document
      DEFAULT_DOCUMENT.merge report.pdf_format.fetch(:document, {})
    end

    def head
      DEFAULT_HEAD.merge report.pdf_format.fetch(:head, {})
    end

    def body
      DEFAULT_BODY.merge report.pdf_format.fetch(:body, {})
    end

    def stamp
      report.pdf_format[:stamp]
    end

    def number_pages
      report.pdf_format.fetch :number_pages, DEFAULT_NUMBER_PAGES
    end
  end
end
