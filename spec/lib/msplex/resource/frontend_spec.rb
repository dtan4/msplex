require "spec_helper"

module Msplex
  module Resource
    describe Frontend do
      let(:pages) do
        [
          {
            name: "index",
            # FIXME
            elements: <<-ELEMENTS,
div#root
  ul
  - @catalog_item_list.each do |obj|
    li obj.name
ELEMENTS
            variables: {
              users: { service: "user", table: "users", action: "list" },
            }
          },
          {
            name: "search",
            # FIXME
            elements: <<-ELEMENTS,
div#root
  input#searchKeyword type: text
ELEMENTS
          }
        ]
      end

      let(:frontend) do
        described_class.new(pages)
      end

      describe ".read_schema" do
        subject { described_class.read_schema(path) }

        context "when the given schema is valid" do
          let(:path) do
            fixture_path("valid_frontend.yml")
          end

          it { is_expected.to be_a described_class }
          its(:pages) { is_expected.to be_a Array }
        end

        context "when the given schema is invalid" do
          pending
        end
      end

      describe "#app_rb" do
        subject { frontend.app_rb }

        it "should generate app.rb" do
          expect(subject).to eq fixture_of("frontend", "app.rb")
        end
      end

      describe "#compose" do
        subject { frontend.compose(services) }

        context "when the frontend has services" do
          let(:services) do
            [
              double(:hoge, name: "hoge", compose_service_name: "hoge_service"),
              double(:fuga, name: "fuga", compose_service_name: "fuga_service"),
            ]
          end

          it "should generate docker-compose.yml linked with services" do
            expect(subject).to eql({
              build: "frontend",
              links: [
                "hoge_service:hoge",
                "fuga_service:fuga",
              ],
              ports: [
                "80:9292"
              ],
            })
          end
        end

        context "when the frontend has no service" do
          let(:services) do
            []
          end

          it "should generate docker-compose.yml linked with services" do
            expect(subject).to eql({
              build: "frontend",
              links: [],
              ports: [
                "80:9292"
              ],
            })
          end
        end
      end

      describe "#config_ru" do
        subject { frontend.config_ru }

        it "should generate config.ru" do
          expect(subject).to eq fixture_of("frontend", "config.ru")
        end
      end

      describe "#dockerfile" do
        subject { frontend.dockerfile }

        it "should generate Dockerfile" do
          expect(subject).to eq fixture_of("frontend", "Dockerfile")
        end
      end

      describe "#gemfile" do
        subject { frontend.gemfile }

        it "should generate Gemfile" do
          expect(subject).to eq fixture_of("frontend", "Gemfile")
        end
      end

      describe "#gemfile_lock" do
        subject { frontend.gemfile_lock }

        it "should generate Gemfile.lock" do
          expect(subject).to eq fixture_of("frontend", "Gemfile.lock")
        end
      end

      describe "#image" do
        subject { frontend.image }

        it { is_expected.to eq "ruby:2.2.3" }
      end

      describe "#layout_html" do
        let(:application) do
          double(:application, name: "<script>sample</script>")
        end

        subject { frontend.layout_html(application) }

        it "should generate Slim template of layout" do
          expect(subject).to eq fixture_of("frontend", "layout.slim")
        end
      end

      describe "#page_htmls" do
        subject { frontend.page_htmls }

        it "should generate Slim templates" do
          expect(subject).to eql([
            {
              name: "index",
              html: <<-HTML
div#root
  ul
  - @catalog_item_list.each do |obj|
    li obj.name
HTML
            },
            {
              name: "search",
              html: <<-HTML
div#root
  input#searchKeyword type: text
HTML
            }
          ])
        end
      end
    end
  end
end
