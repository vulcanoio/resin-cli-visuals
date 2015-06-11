_ = require('lodash')
chai = require('chai')
expect = chai.expect
sinon = require('sinon')
chai.use(require('sinon-chai'))
inquirer = require('inquirer')
form = require('../lib/form')

describe 'Form:', ->

	describe '.parse()', ->

		describe 'given a select input', ->

			beforeEach ->
				@form = [
					label: 'Processor'
					name: 'processorType'
					type: 'select'
					values: [ 'Z7010', 'Z7020' ]
				]

			it 'should create a valid inquirer list question', ->
				question = form.parse(@form)
				expect(question).to.deep.equal [
					type: 'list'
					name: 'processorType'
					message: 'Processor'
					choices: [ 'Z7010', 'Z7020' ]
				]

		describe 'given a checkbox input', ->

			beforeEach ->
				@form = [
					label: 'HDMI'
					name: 'hdmi'
					type: 'checkbox'
					value: 1
				]

			it 'should create a valid inquirer list question', ->
				question = form.parse(@form)
				expect(question).to.deep.equal [
					type: 'confirm'
					name: 'hdmi'
					message: 'HDMI'
					default: true
				]

		describe 'given a text input', ->

			beforeEach ->
				@form = [
					label: 'Wifi Key'
					name: 'wifiKey'
					type: 'text'
				]

			it 'should create a valid inquirer input question', ->
				question = form.parse(@form)
				expect(question).to.deep.equal [
					type: 'input'
					name: 'wifiKey'
					message: 'Wifi Key'
				]

		describe 'given a text input with a default value', ->

			beforeEach ->
				@form = [
					label: 'Project'
					name: 'project'
					type: 'text'
					value: 'MyCoolProject'
				]

			it 'should create a valid inquirer input question', ->
				question = form.parse(@form)
				expect(question).to.deep.equal [
					type: 'input'
					name: 'project'
					message: 'Project'
					default: 'MyCoolProject'
				]

		describe 'given a password input', ->

			beforeEach ->
				@form = [
					label: 'Password'
					name: 'password'
					type: 'password'
				]

			it 'should create a valid inquirer password question', ->
				question = form.parse(@form)
				expect(question).to.deep.equal [
					type: 'password'
					name: 'password'
					message: 'Password'
				]

		describe 'given an unknown input', ->

			beforeEach ->
				@form = [
					label: 'HDMI'
					name: 'hdmi'
					type: 'foobar'
					value: 1
				]

			it 'should throw an error', ->
				expect =>
					form.parse(@form)
				.to.throw('Unsupported option type: foobar')

		describe 'given an input with a validate property', ->

			beforeEach ->
				@form = [
					label: 'Coprocessor cores'
					name: 'coprocessorCore'
					type: 'select'
					values: [ '16', '64' ]
					validate: _.noop
				]

			it 'should keep the validate function', ->
				questions = form.parse(@form)
				expect(questions[0].validate).to.deep.equal(_.noop)

		describe 'given an input with an when property', ->

			describe 'given a single value when', ->

				beforeEach ->
					@form = [
						label: 'Coprocessor cores'
						name: 'coprocessorCore'
						type: 'select'
						values: [ '16', '64' ]
						when:
							processorType: 'Z7010'
					]

				it 'should return a when function', ->
					questions = form.parse(@form)
					expect(questions[0].when).to.be.a('function')

				it 'should return true if the condition is met', ->
					questions = form.parse(@form)
					expect(questions[0].when(processorType: 'Z7010')).to.be.true

				it 'should return false if the condition is not met', ->
					questions = form.parse(@form)
					expect(questions[0].when(processorType: 'Z7020')).to.be.false

				it 'should return false if the property does not exist', ->
					questions = form.parse(@form)
					expect(questions[0].when(foo: 'Z7020')).to.be.false

				it 'should return false if no answer', ->
					questions = form.parse(@form)
					expect(questions[0].when()).to.be.false
					expect(questions[0].when({})).to.be.false

			describe 'given a multiple value when', ->

				beforeEach ->
					@form = [
						label: 'Coprocessor cores'
						name: 'coprocessorCore'
						type: 'select'
						values: [ '16', '64' ]
						when:
							processorType: 'Z7010'
							hdmi: true
					]

				it 'should return true if all the conditions are met', ->
					questions = form.parse(@form)
					expect(questions[0].when(processorType: 'Z7010', hdmi: true)).to.be.true

				it 'should return false if any condition is not met', ->
					questions = form.parse(@form)
					expect(questions[0].when(processorType: 'Z7020', hdmi: false)).to.be.false

	describe '.run()', ->

		beforeEach ->
			@inquirerPromptStub = sinon.stub(inquirer, 'prompt')
			@inquirerPromptStub.yields({ foo: 'bar' })

		afterEach ->
			@inquirerPromptStub.restore()

		it 'should call inquirer with the parsed questions', (done) ->
			form.run [
				label: 'Processor'
				name: 'processorType'
				type: 'select'
				values: [ 'Z7010', 'Z7020' ]
			,
				label: 'HDMI'
				name: 'hdmi'
				type: 'checkbox'
				value: 1
			], (error, result) =>
				expect(error).to.not.exist
				expect(@inquirerPromptStub).to.have.been.calledWith [
					type: 'list'
					name: 'processorType'
					message: 'Processor'
					choices: [ 'Z7010', 'Z7020' ]
				,
					type: 'confirm'
					name: 'hdmi'
					message: 'HDMI'
					default: true
				]
				done()

		it 'should pass the result as the second argument of the callback', (done) ->
			form.run [
				label: 'Processor'
				name: 'processorType'
				type: 'select'
				values: [ 'Z7010', 'Z7020' ]
			], (error, result) ->
				expect(error).to.not.exist
				expect(result).to.deep.equal(foo: 'bar')
				done()

	describe '.ask()', ->

		describe 'given there is an error running the question', ->

			beforeEach ->
				@formRunStub = sinon.stub(form, 'run')
				@formRunStub.yields(new Error('form error'))

			afterEach ->
				@formRunStub.restore()

			it 'should yield the error', (done) ->
				form.ask
					label: 'Processor'
					type: 'select'
					values: [ 'Z7010', 'Z7020' ]
				, (error, answer) ->
					expect(error).to.be.an.instanceof(Error)
					expect(error.message).to.equal('form error')
					expect(answer).to.not.exist
					done()

		describe 'given there is not an error running the question', ->

			describe 'given a question without a name property', ->

				beforeEach ->
					@formRunStub = sinon.stub(form, 'run')
					@formRunStub.yields(null, question: 'Z7010')

				afterEach ->
					@formRunStub.restore()

				it 'should give the answer back', (done) ->
					form.ask
						label: 'Processor'
						type: 'select'
						values: [ 'Z7010', 'Z7020' ]
					, (error, answer) ->
						expect(error).to.not.exist
						expect(answer).to.equal('Z7010')
						done()

			describe 'given a question with a name property', ->

				beforeEach ->
					@formRunStub = sinon.stub(form, 'run')
					@formRunStub.yields(null, processorType: 'Z7010')

				afterEach ->
					@formRunStub.restore()

				it 'should give the answer back', (done) ->
					form.ask
						label: 'Processor'
						type: 'select'
						name: 'processorType'
						values: [ 'Z7010', 'Z7020' ]
					, (error, answer) ->
						expect(error).to.not.exist
						expect(answer).to.equal('Z7010')
						done()